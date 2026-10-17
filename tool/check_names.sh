#!/bin/bash
# The two standing rules (SIX-168), checked against every tracked file's path
# and its contents, binary files (image metadata) included:
#
#   FOUNDER_NAMES        the founders' names, separated by commas or new
#                        lines. None may appear as a word (an ASCII letter
#                        on either side makes it another word; a digit, _ or
#                        any other character or byte does not):
#                        the founder is named in public only where the law
#                        requires, and the site is not such a place.
#   DISGUISE_NAME_CHECK  the names the app goes by on her phone in a release,
#                        separated the same way. None may appear in any form.
#
# Both match in any case, with the words apart, run together, or joined by
# _ - . or /, across a line break too. Non-ASCII letters fold case in UTF-8
# files; a name in a latin1 file is found in the case given (see search()).
#
# The names are never written in this repository: CI supplies them from
# secrets. A hit is reported without the name: a file by path and line, or,
# when the path itself holds the name, by its number in `git ls-files`
# (see it with: git ls-files | sed -n <number>p).
#
# Unset locally, a check is skipped and says so. Unset in CI ($CI is true),
# it fails, because a check that never runs protects nothing.
#
#   FOUNDER_NAMES='…' DISGUISE_NAME_CHECK='…' tool/check_names.sh

set -euo pipefail
export LC_ALL=C.UTF-8   # each grep sets its own locale; see search()

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TRACKED=()
while IFS= read -r -d '' path; do TRACKED+=("$path"); done < <(git ls-files -z)
if [ "${#TRACKED[@]}" = 0 ]; then
  echo "FAIL: git lists no tracked files, so nothing could be checked."
  exit 2
fi

# Every grep gets the patterns as arguments, so no name is written to disk.
# Its status 0 is a match and 1 none; anything else stops the check.
die_on_error() {
  [ "$1" -le 1 ] || { echo "FAIL: grep failed (status $1)." >&2; exit 2; }
}

# One grep in locale $1, the rest its arguments; an error stops the check.
g() {
  local loc="$1" rc=0
  shift
  LC_ALL="$loc" grep "$@" || rc=$?
  die_on_error "$rc"
  return "$rc"
}

# Each search is run up to three times, and a hit in any run counts:
#   - in UTF-8, so non-ASCII letters fold case and count as letters;
#   - in the C locale, where every byte that is not an ASCII letter counts as
#     a non-letter, so a name beside a byte that is not valid UTF-8 (binary
#     data, a latin1 symbol in image metadata) is still caught;
#   - in the C locale with the names in latin1, when they differ, so a name
#     with non-ASCII letters is caught in a latin1-encoded file (its
#     non-ASCII letters then match only in the case given).
# The patterns are in the arrays PATTERNS_UTF8 and PATTERNS_LATIN1.
search() {  # search <grep options> <file>, or <grep options> - <text>
  local opts="$1" target="$2" text="${3:-}"
  g C.UTF-8 "$opts" "${PATTERNS_UTF8[@]}" -- "$target" <<< "$text" && return 0
  g C "$opts" "${PATTERNS_UTF8[@]}" -- "$target" <<< "$text" && return 0
  if [ "${#PATTERNS_LATIN1[@]}" -gt 0 ]; then
    g C "$opts" "${PATTERNS_LATIN1[@]}" -- "$target" <<< "$text" && return 0
  fi
  return 1
}

# Prints the numbers of the lines of file $1 that any run matches.
matching_lines() {
  local opts=(-naiE)
  {
    g C.UTF-8 "${opts[@]}" "${PATTERNS_UTF8[@]}" -- "$1" || true
    g C "${opts[@]}" "${PATTERNS_UTF8[@]}" -- "$1" || true
    if [ "${#PATTERNS_LATIN1[@]}" -gt 0 ]; then
      g C "${opts[@]}" "${PATTERNS_LATIN1[@]}" -- "$1" || true
    fi
  } | LC_ALL=C cut -d: -f1 | sort -un
}

# Prints one line per tracked file whose path or contents hold a match. Every
# path is checked first: a path that holds the name is never printed, only its
# number. Contents are read whole (-z, so a name split across lines is
# caught) and byte for byte (-a).
find_in_tracked() {
  local i=0 path lines line rc
  for path in "${TRACKED[@]}"; do
    i=$((i + 1))
    if search -qzaiE - "$path"; then
      echo "tracked file $i (its path holds the name)"
      continue
    fi
    [ -f "$path" ] || continue
    search -qzaiE "$path" || continue
    rc=0; lines="$(matching_lines "$path")" || rc=$?
    [ "$rc" = 0 ] || exit 2
    if [ -n "$lines" ]; then
      while IFS= read -r line; do echo "$path:$line"; done <<< "$lines"
    else
      echo "$path (across a line break)"
    fi
  done
}

# Turns one name into an extended regex: each word escaped, the words joined by
# any run of spaces, _, -, . or /, so "A B", "AB", "a_b" and "a/b" all match.
loose_pattern() {
  local word out="" words
  read -ra words <<< "$1"
  for word in "${words[@]}"; do
    word="$(printf '%s' "$word" | sed -E 's/[][\.*^$+?(){}|\/]/\\&/g')"
    out="${out:+$out[[:space:]_./-]*}$word"
  done
  printf '%s' "$out"
}

status=0

check() {
  local var="$1" what="$2" mode="$3" raw="${!1:-}"
  raw="${raw//$'\r'/,}"
  raw="${raw//$'\n'/,}"
  if [ -z "${raw//[[:space:],]/}" ]; then
    if [ "${CI:-}" = "true" ]; then
      echo "FAIL: $var is not set, so $what was not checked. Set it as a repository secret."
      status=1
    else
      echo "SKIP: $var is not set, so $what was not checked. CI sets it from a secret."
    fi
    return
  fi
  local name names pattern latin1
  PATTERNS_UTF8=()
  PATTERNS_LATIN1=()
  IFS=',' read -ra names <<< "$raw"
  for name in "${names[@]}"; do
    name="$(printf '%s' "$name" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -z "$name" ] && continue
    if [ "$mode" = word ]; then
      pattern="(^|[^[:alpha:]])$(loose_pattern "$name")($|[^[:alpha:]])"
    else
      pattern="$(loose_pattern "$name")"
    fi
    PATTERNS_UTF8+=(-e "$pattern")
    if latin1="$(printf '%s' "$pattern" | iconv -f UTF-8 -t LATIN1 2> /dev/null)" \
        && [ "$latin1" != "$pattern" ]; then
      PATTERNS_LATIN1+=(-e "$latin1")
    fi
  done
  local found
  found="$(find_in_tracked)" || exit 2
  if [ -n "$found" ]; then
    echo "FAIL: $what appears in tracked files (the name is not shown):"
    printf '%s\n' "$found" | sed 's/^/  /'
    status=1
  else
    echo "OK: $what appears in none of the ${#TRACKED[@]} tracked files or their paths."
  fi
}

check FOUNDER_NAMES "a founder's name" word
check DISGUISE_NAME_CHECK "the disguise name" loose

exit $status
