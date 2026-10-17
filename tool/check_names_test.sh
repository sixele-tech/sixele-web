#!/bin/bash
# Tests for tool/check_names.sh (SIX-168). Each case builds a throwaway git
# repository holding a copy of the check and a few made-up files, runs the
# check there and looks at its exit status and output. The names used are
# invented ("Zorblax", "Quux"); no real name is ever written here.
#
#   tool/check_names_test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/check_names.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

passed=0
failed=0
n=0
REPO=""

# Starts a fresh repository. The check itself is not added to git's list, so
# a case controls exactly which files are tracked.
new_repo() {
  n=$((n + 1))
  REPO="$WORK/repo$n"
  mkdir -p "$REPO/tool"
  git -C "$REPO" init -q
  cp "$CHECK" "$REPO/tool/check_names.sh"
}

# Writes $2 (printf format, so \n works) to $1 in the repository and tracks it.
track() {
  mkdir -p "$(dirname "$REPO/$1")"
  printf "$2" > "$REPO/$1"
  git -C "$REPO" add -- "$1"
}

# Runs the check outside CI with the given VAR=value pairs.
run_check() {
  OUT="$(env -u CI -u FOUNDER_NAMES -u DISGUISE_NAME_CHECK "$@" \
    "$REPO/tool/check_names.sh" 2>&1)"
  RC=$?
}

ok() { passed=$((passed + 1)); echo "ok   - $1"; }
not_ok() {
  failed=$((failed + 1)); echo "FAIL - $1"
  printf '%s\n' "$OUT" | sed 's/^/       | /'
}

# expect <description> <exit status> [text the output must contain] ...
# Every case also requires that no test name appears in the output.
expect() {
  local what="$1" want="$2" needle
  shift 2
  if [ "$RC" != "$want" ]; then not_ok "$what (exit $RC, wanted $want)"; return; fi
  if printf '%s' "$OUT" | grep -qiE 'zorblax|quux|zo[^[:space:]]{0,2}b'; then
    not_ok "$what (the output shows a name)"; return
  fi
  for needle in "$@"; do
    if ! printf '%s' "$OUT" | grep -qF -- "$needle"; then
      not_ok "$what (output lacks \"$needle\")"; return
    fi
  done
  ok "$what"
}

# A clean repository passes both checks.
new_repo
track index.html 'Sixele speaks as itself.\n'
run_check FOUNDER_NAMES='Quux Smith' DISGUISE_NAME_CHECK='Zorblax'
expect 'a clean repository passes' 0 'OK: a founder' 'OK: the disguise name'
run_check FOUNDER_NAMES=' , ' DISGUISE_NAME_CHECK=$'\n\r\n'
expect 'a secret of only commas and line breaks counts as unset' 0 'SKIP: FOUNDER_NAMES' 'SKIP: DISGUISE_NAME_CHECK'

# Unset locally, each check is skipped; unset in CI, the check fails.
run_check
expect 'unset names are skipped locally' 0 'SKIP: FOUNDER_NAMES' 'SKIP: DISGUISE_NAME_CHECK'
run_check CI=true
expect 'unset names fail in CI' 1 'FAIL: FOUNDER_NAMES' 'FAIL: DISGUISE_NAME_CHECK'

# A name in a file's contents is reported by path and line.
new_repo
track index.html 'one\ntwo zorblax three\n'
run_check DISGUISE_NAME_CHECK='Zorblax'
expect 'a name in the contents is reported by path and line' 1 'index.html:2'

# A name in a tracked path fails, and neither the path nor the name is shown.
new_repo
track index.html 'clean\n'
track notes/ZORBLAX-plan.txt 'clean\n'
run_check DISGUISE_NAME_CHECK='Zorblax'
expect 'a disguise name in a path fails without showing the path' 1 \
  'tracked file 2 (its path holds the name)'

new_repo
track index.html 'clean\n'
track team/quux_smith.md 'clean\n'
run_check FOUNDER_NAMES='Quux Smith'
expect "a founder's name in a path fails without showing the path" 1 \
  'tracked file 2 (its path holds the name)'

# A file whose path and contents both hold the name is given only by its
# number, never by its path.
new_repo
track zorblax.txt 'zorblax\n'
run_check DISGUISE_NAME_CHECK='Zorblax'
expect 'a named path holding the name inside too shows only its number' 1 \
  'tracked file 1 (its path holds the name)'

# Several names: comma-separated, newline-separated, or both. Every one is
# checked, not only the first.
for secret in 'Alpha,Zorblax' $'Alpha\nZorblax' $'Alpha\r\nZorblax\n' $'Alpha,\nBeta, Zorblax'; do
  new_repo
  track index.html 'a zorblax here\n'
  run_check DISGUISE_NAME_CHECK="$secret"
  expect "every name of a multi-name secret is checked ($(printf '%q' "$secret" | sed 's/Zorblax/<name>/'))" 1 'index.html:1'
done
new_repo
track index.html 'a quux smith here\n'
run_check FOUNDER_NAMES=$'Alpha Beta\nQuux Smith'
expect 'every founder of a newline-separated secret is checked' 1 'index.html:1'

# A founder's name is a word: a letter beside it is another word, but _ and
# digits are not letters, so a name beside them still counts.
for text in 'quux_' '_quux' 'quux2' '9quux' 'x.quux.y' 'quux'; do
  new_repo
  track index.html "see $text here\n"
  run_check FOUNDER_NAMES='Quux'
  expect "a founder's name beside _ or a digit is found ($(printf '%s' "$text" | sed 's/quux/<name>/'))" 1 'index.html:1'
done
for text in 'quuxly' 'aquux'; do
  new_repo
  track index.html "see $text here\n"
  run_check FOUNDER_NAMES='Quux'
  expect "a founder's name inside a longer word is not a hit" 0 'OK: a founder'
done

# A name with a letter outside ASCII is found, in any case.
for text in 'Zoëb' 'ZOËB' 'zoëb'; do
  new_repo
  track index.html "by $text here\n"
  run_check DISGUISE_NAME_CHECK='Zoëb'
  expect 'a name with a non-ASCII letter is found in any case' 1 'index.html:1'
done

# In a binary file (image metadata) a founder's name beside bytes that are not
# UTF-8 is still a word, and still found.
new_repo
track brand/mark.jpg '\377\330\377quux\377\000 x\n'
track brand/other.bin 'ab\351quux\351 x\n'
run_check FOUNDER_NAMES='Quux'
expect "a founder's name beside bytes that are not UTF-8 is found" 1 \
  'brand/mark.jpg:1' 'brand/other.bin:1'

# A name split across a line break is found.
new_repo
track index.html 'the zorblax\nquux app\n'
run_check DISGUISE_NAME_CHECK='Zorblax Quux'
expect 'a name across a line break is found' 1 'index.html (across a line break)'

# A repository in which git lists no file fails: a check of nothing is no check.
new_repo
run_check FOUNDER_NAMES='Quux' DISGUISE_NAME_CHECK='Zorblax'
expect 'no tracked files fails' 2 'git lists no tracked files'

echo "$passed passed, $failed failed"
[ "$failed" = 0 ]
