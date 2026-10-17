#!/bin/bash
# The two standing rules (SIX-168), checked against every tracked file's path
# and its contents, binary files (image metadata) included:
#
#   FOUNDER_NAMES        the founders' names, separated by commas or new
#                        lines. None may appear as a word (a letter on either
#                        side makes it another word; a digit or _ does not):
#                        the founder is named in public only where the law
#                        requires, and the site is not such a place.
#   DISGUISE_NAME_CHECK  the names the app goes by on her phone in a release,
#                        separated the same way. None may appear in any form.
#
# Both match in any case, non-ASCII letters included, with the words apart,
# run together, or joined by _ - . or /, across a line break too.
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
export LC_ALL=C.UTF-8   # case-folding and letter classes for non-ASCII names

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

# Prints one line per tracked file whose path or contents hold a match. Every
# path is checked first: a path that holds the name is never printed, only its
# number. Contents are read whole (-z, so a name split across lines is
# caught) and byte for byte (-a). The arguments are the -e patterns.
find_in_tracked() {
  local i=0 path lines line rc
  for path in "${TRACKED[@]}"; do
    i=$((i + 1))
    rc=0; grep -qzaiE "$@" <<< "$path" || rc=$?
    die_on_error "$rc"
    if [ "$rc" = 0 ]; then
      echo "tracked file $i (its path holds the name)"
      continue
    fi
    [ -f "$path" ] || continue
    rc=0; grep -qzaiE "$@" -- "$path" || rc=$?
    die_on_error "$rc"
    [ "$rc" = 0 ] || continue
    rc=0; lines="$(grep -naiE "$@" -- "$path" | cut -d: -f1)" || rc=$?
    die_on_error "$rc"
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
  local args=() name names
  IFS=',' read -ra names <<< "$raw"
  for name in "${names[@]}"; do
    name="$(printf '%s' "$name" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -z "$name" ] && continue
    if [ "$mode" = word ]; then
      args+=(-e "(^|[^[:alpha:]])$(loose_pattern "$name")($|[^[:alpha:]])")
    else
      args+=(-e "$(loose_pattern "$name")")
    fi
  done
  local found
  found="$(find_in_tracked "${args[@]}")" || exit 2
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
