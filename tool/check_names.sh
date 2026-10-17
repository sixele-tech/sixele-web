#!/bin/bash
# The two standing rules (SIX-168), checked against every tracked text file:
#
#   FOUNDER_NAMES        comma-separated names of the founders. None may appear
#                        as a word: the founder is named in public only where
#                        the law requires, and the site is not such a place.
#   DISGUISE_NAME_CHECK  comma-separated names the app goes by on her phone in
#                        a release. None may appear in any form (any case, the
#                        words run together or joined by _ - or .).
#
# The names are never written in this repository: CI supplies them from
# secrets. A name found is reported by file and line only, never echoed.
#
# Unset locally, a check is skipped and says so. Unset in CI ($CI is true),
# it fails, because a check that never runs protects nothing.
#
#   FOUNDER_NAMES='…' DISGUISE_NAME_CHECK='…' tool/check_names.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

# Prints file:line for every tracked text file that matches; grep reads the
# patterns from its arguments, so no name is written to disk.
find_in_tracked() {
  git ls-files -z | xargs -0 grep -nIiE "$@" -- 2>/dev/null | cut -d: -f1,2 || true
}

# Turns one name into an extended regex: each word escaped, the words joined by
# any run of spaces, _, - or ., so "A B", "AB", "a_b" and "a-b" all match.
loose_pattern() {
  local word out="" words
  read -ra words <<< "$1"
  for word in "${words[@]}"; do
    word="$(printf '%s' "$word" | sed -E 's/[][\.*^$+?(){}|\/]/\\&/g')"
    out="${out:+$out[[:space:]_.-]*}$word"
  done
  printf '%s' "$out"
}

check() {
  local var="$1" what="$2" mode="$3" raw="${!1:-}"
  if [ -z "${raw//[[:space:],]/}" ]; then
    if [ "${CI:-}" = "true" ]; then
      echo "FAIL: $var is not set, so $what was not checked. Set it as a repository secret."
      status=1
    else
      echo "SKIP: $var is not set, so $what was not checked. CI sets it from a secret."
    fi
    return
  fi
  local args=() name
  IFS=',' read -ra names <<< "$raw"
  for name in "${names[@]}"; do
    name="$(printf '%s' "$name" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -z "$name" ] && continue
    if [ "$mode" = word ]; then
      args+=(-e "(^|[^[:alnum:]_])$(loose_pattern "$name")($|[^[:alnum:]_])")
    else
      args+=(-e "$(loose_pattern "$name")")
    fi
  done
  local found
  found="$(find_in_tracked "${args[@]}")"
  if [ -n "$found" ]; then
    echo "FAIL: $what appears in tracked files (the name is not shown):"
    printf '%s\n' "$found" | sed 's/^/  /'
    status=1
  else
    echo "OK: $what appears in no tracked file."
  fi
}

check FOUNDER_NAMES "a founder's name" word
check DISGUISE_NAME_CHECK "the disguise name" loose

exit $status
