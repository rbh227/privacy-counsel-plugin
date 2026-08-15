#!/usr/bin/env bash
# Tests the harness itself. Pure bash, no live sessions, no tokens — so
# scripts/static-checks.sh runs it on every commit.
#
# It exists because of one bug class: an assertion helper that reports PASS
# when it could not actually evaluate. grep exits 2 on an invalid pattern,
# and every helper here once read "non-zero" as "the thing is absent". A
# typo'd regex then scored a pass, which is worse than no assertion at all —
# it reads as coverage in the results.
#
# Every regex-taking helper must fail on an invalid pattern. Add a case here
# when you add a helper.
set -u
cd "$(dirname "$0")/.."

TESTS_DIR="$PWD/tests"

# EXPORTED, not assigned: lib.sh sets RESULTS_ROOT="${PC_RESULTS_ROOT:-…/.results}",
# so a plain assignment here is silently overwritten when lib.sh is sourced —
# and the cleanup at the bottom then deletes the REAL results directory,
# destroying a live run's transcripts. That happened once. Hence both the
# export and the guard on the rm.
PC_RESULTS_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pc-selftest.XXXXXX")"
export PC_RESULTS_ROOT
RUN_STAMP="selftest"
export RUN_STAMP
mkdir -p "$PC_RESULTS_ROOT/$RUN_STAMP"

# shellcheck source=/dev/null
. "$TESTS_DIR/lib.sh"

RESULT_DIR="$RESULTS_ROOT/$RUN_STAMP/case"
mkdir -p "$RESULT_DIR"
printf 'hello world\nthe partner reviews it\n' > "$RESULT_DIR/t1.txt"
printf 'breach/notice-window: 48h from awareness\n' > "$RESULT_DIR/state.md"

BAD='(|a|b)'          # empty alternative — grep -E exits 2
fails=0
expect() { # expect <wanted-pass> <wanted-fail> <label>
  if [ "$ASSERT_PASS" != "$1" ] || [ "$ASSERT_FAIL" != "$2" ]; then
    echo "  SELFTEST FAIL: $3 — got pass=$ASSERT_PASS fail=$ASSERT_FAIL, wanted pass=$1 fail=$2"
    fails=$((fails + 1))
  fi
  ASSERT_PASS=0; ASSERT_FAIL=0
}

run_quiet() { "$@" > /dev/null 2>&1; }

ASSERT_PASS=0; ASSERT_FAIL=0

# --- every regex helper must FAIL on an invalid pattern -------------------
run_quiet assert_match       t1 "$BAD" x;            expect 0 1 "assert_match rejects invalid regex"
run_quiet assert_absent      t1 "$BAD" x;            expect 0 1 "assert_absent rejects invalid regex"
run_quiet assert_head_match  t1 5 "$BAD" x;          expect 0 1 "assert_head_match rejects invalid regex"
run_quiet assert_head_absent t1 5 "$BAD" x;          expect 0 1 "assert_head_absent rejects invalid regex"
run_quiet assert_file_match  "$RESULT_DIR/state.md" "$BAD" x
expect 0 1 "assert_file_match rejects invalid regex"
run_quiet assert_file_absent_match "$RESULT_DIR/state.md" "$BAD" x
expect 0 1 "assert_file_absent_match rejects invalid regex"

# --- and must still behave on valid patterns ------------------------------
run_quiet assert_match       t1 "hello" x;           expect 1 0 "assert_match matches"
run_quiet assert_match       t1 "zebra" x;           expect 0 1 "assert_match misses"
run_quiet assert_absent      t1 "zebra" x;           expect 1 0 "assert_absent absent"
run_quiet assert_absent      t1 "hello" x;           expect 0 1 "assert_absent present"
run_quiet assert_head_match  t1 2 "hello" x;         expect 1 0 "assert_head_match in head"
run_quiet assert_head_match  t1 2 "partner" x;       expect 0 1 "assert_head_match past head"
run_quiet assert_head_absent t1 2 "partner" x;       expect 1 0 "assert_head_absent past head"
run_quiet assert_file_match  "$RESULT_DIR/state.md" "^breach/notice-window: *48" x
expect 1 0 "assert_file_match hits"
run_quiet assert_file_match  "$RESULT_DIR/nope.md" "anything" x
expect 0 1 "assert_file_match fails on a missing file"
run_quiet assert_file_absent_match "$RESULT_DIR/state.md" "liability" x
expect 1 0 "assert_file_absent_match absent"

# Only ever delete a directory this script created.
case "$RESULTS_ROOT" in
  */pc-selftest.*) rm -rf "$RESULTS_ROOT" ;;
  *) echo "selftest: refusing to delete $RESULTS_ROOT — not a self-test temp dir" >&2; fails=$((fails + 1)) ;;
esac

if [ "$fails" -ne 0 ]; then
  echo "harness self-test: $fails case(s) failed"
  exit 1
fi
echo "harness self-test: OK"
exit 0
