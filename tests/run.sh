#!/bin/bash
# privacy-counsel scenario runner.
#
#   tests/run.sh <scenario-id>     run one scenario
#   tests/run.sh --all             static checks + every runnable scenario
#   tests/run.sh --list            show the scenario table
#
# Scenarios spawn real `claude -p` sessions. They cost tokens and minutes —
# run the ones your change touches during development, `--all` at the gate.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TESTS_DIR/lib.sh"

NO_WEB=0
PARTIAL=0
KEEP_CWD=0
MODE=""
TARGET=""

usage() {
  cat <<'EOF'
Usage:
  tests/run.sh <scenario-id> [options]   run a single scenario
  tests/run.sh --all [options]           static checks + the whole battery
  tests/run.sh --list                    list scenarios and their status

Options:
  --no-web         skip web-research scenarios (slow, token-heavy). They run
                   by default: a battery that silently drops them is not the
                   battery ticket 09 gates on.
  --partial        accept a run that skips scenarios. Without it, --all fails
                   when anything is skipped — including scenarios still
                   pending on a later ticket.
  --keep-cwd       keep the neutral temp cwd for each scenario (debugging)

Every run redirects the plugin's state root (PRIVACY_COUNSEL_HOME) to a
per-run directory under the results dir, so scenarios never touch real
matters, and starts with one preflight session proving the sessions load
this tree.

Environment:
  PC_CLAUDE_BIN    path to the claude binary (default: first on PATH)
  PC_MODEL         model for every scenario session (default: opus)
  PC_STATE_DIR     override the per-run state root (never the production one)
  PC_RESULTS_ROOT  override tests/.results
  PC_TURN_TIMEOUT  per-turn wall-clock ceiling in seconds (default 900)
  PC_MAX_COST_USD  cumulative spend ceiling for the run (default 10)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all)         MODE="all" ;;
    --list|-l)     MODE="list" ;;
    --no-web)      NO_WEB=1 ;;
    --partial)     PARTIAL=1 ;;
    --keep-cwd)    KEEP_CWD=1 ;;
    -h|--help)     usage; exit 0 ;;
    -*)            echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)             MODE="one"; TARGET="$1" ;;
  esac
  shift
done

[ -n "$MODE" ] || { usage >&2; exit 2; }

scenario_files() { ls "$TESTS_DIR"/scenarios/*.sh 2>/dev/null | sort; }

meta() { sed -n "s/^$2=\"\(.*\)\"\$/\1/p" "$1" | head -1; }

resolve_scenario() {
  local want="$1" f
  for f in $(scenario_files); do
    if [ "$(meta "$f" SCENARIO_ID)" = "$want" ] || [ "$(basename "$f" .sh)" = "$want" ]; then
      echo "$f"; return 0
    fi
  done
  return 1
}

# run_scenario <file> — subshell so scenario globals never leak between runs.
# Exit codes: 0 passed, 1 assertions failed, 3 skipped (did not run).
run_scenario() (
  SCENARIO_FILE="$1"
  SCENARIO_ID=""
  SCENARIO_TITLE=""
  SCENARIO_STATUS="active"
  SCENARIO_TAGS=""
  SCENARIO_TOOLS="$DEFAULT_TOOLS"
  SCENARIO_ADD_STATE=0
  SCENARIO_ADD_DIRS=""
  SCENARIO_BLOCKED_BY=""
  CRITERIA_LINES=""
  ASSERT_PASS=0
  ASSERT_FAIL=0
  SCENARIO_ABORTED=0
  LAST_SID=""

  . "$SCENARIO_FILE"
  [ -n "$SCENARIO_ID" ] || _die "no SCENARIO_ID in $SCENARIO_FILE"

  echo
  echo "=== $SCENARIO_ID — $SCENARIO_TITLE"

  if [ "$SCENARIO_STATUS" = "pending" ]; then
    echo "  SKIP  pending — blocked by ${SCENARIO_BLOCKED_BY:-a later ticket}"
    echo "  pass criteria are written and will run once that ticket lands:"
    printf '%s\n' "$CRITERIA_LINES" | sed '/^$/d'
    exit 3
  fi

  case " $SCENARIO_TAGS " in
    *" web "*)
      if [ "$NO_WEB" = "1" ]; then
        echo "  SKIP  web-research scenario — --no-web"
        exit 3
      fi
      ;;
  esac

  RESULT_DIR="$RESULTS_ROOT/$RUN_STAMP/$SCENARIO_ID"
  mkdir -p "$RESULT_DIR"
  NEUTRAL_CWD="$(mktemp -d "${TMPDIR:-/tmp}/privacy-counsel-scenario.XXXXXX")"

  # Scenarios always run from a neutral cwd: a session started inside this
  # repo would pick up repo context and grade the harness, not the plugin.
  scenario_run

  if [ -n "$CRITERIA_LINES" ]; then
    echo "  --- human grading -----------------------------------------------"
    echo "  transcripts: $RESULT_DIR"
    printf '%s\n' "$CRITERIA_LINES" | sed '/^$/d'
  fi

  if [ "$KEEP_CWD" = "1" ]; then
    echo "  session cwd kept: $NEUTRAL_CWD"
  else
    rm -rf "$NEUTRAL_CWD"
  fi

  if [ "$ASSERT_FAIL" -eq 0 ]; then
    echo "  == $SCENARIO_ID: $ASSERT_PASS machine assertions passed"
    exit 0
  fi
  echo "  == $SCENARIO_ID: $ASSERT_FAIL FAILED, $ASSERT_PASS passed"
  exit 1
)

# ------------------------------------------------------------------- modes

if [ "$MODE" = "list" ]; then
  printf '%-26s %-9s %-10s %s\n' ID STATUS TAGS TITLE
  for f in $(scenario_files); do
    printf '%-26s %-9s %-10s %s\n' \
      "$(meta "$f" SCENARIO_ID)" \
      "$(meta "$f" SCENARIO_STATUS)" \
      "$(meta "$f" SCENARIO_TAGS)" \
      "$(meta "$f" SCENARIO_TITLE)"
  done
  exit 0
fi

RUN_STAMP="$(date +%Y%m%d-%H%M%S)"
export RUN_STAMP
mkdir -p "$RESULTS_ROOT/$RUN_STAMP"
init_state_root

# What produced these results. Without it a saved run is ungradeable later:
# "it passed" means nothing if the model, CLI, or tree is unknown.
{
  echo "run:        $RUN_STAMP"
  echo "repo root:  $REPO_ROOT"
  echo "commit:     $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "dirty:      $(git -C "$REPO_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ') files"
  echo "model:      $PC_MODEL"
  echo "claude:     $("$CLAUDE_BIN" --version 2>/dev/null || echo unknown)"
  echo "state root: $STATE_DIR"
  echo "cost cap:   \$$MAX_COST_USD"
} > "$RESULTS_ROOT/$RUN_STAMP/manifest.txt"
cat "$RESULTS_ROOT/$RUN_STAMP/manifest.txt"
echo

fail=0
skipped=0
skipped_ids=""

preflight || exit 1

if [ "$MODE" = "all" ]; then
  echo
  echo "=== static checks"
  if "$REPO_ROOT/scripts/static-checks.sh"; then :; else fail=1; fi

  total=0
  for f in $(scenario_files); do
    total=$((total + 1))
    run_scenario "$f"
    case $? in
      0) ;;
      3) skipped=$((skipped + 1)); skipped_ids="$skipped_ids $(meta "$f" SCENARIO_ID)" ;;
      *) fail=1 ;;
    esac
  done

  echo
  echo "results: $RESULTS_ROOT/$RUN_STAMP"
  echo "cost:    \$$(awk -F'\t' '{ s += $2 } END { printf "%.2f", s }' \
                      "$RESULTS_ROOT/$RUN_STAMP/cost.tsv" 2>/dev/null || echo 0)"

  if [ "$skipped" -gt 0 ] && [ "$PARTIAL" != "1" ]; then
    echo "=== INCOMPLETE — $skipped of $total scenarios did not run:$skipped_ids"
    echo "    --all is the ticket-09 gate. A run that skips part of the battery"
    echo "    is not a green battery. Re-run with --partial to accept this"
    echo "    during development, or land the tickets those scenarios wait on."
    fail=1
  elif [ "$fail" -eq 0 ] && [ "$skipped" -gt 0 ]; then
    echo "=== PARTIAL PASS — $skipped of $total skipped:$skipped_ids"
    echo "    Machine assertions passed for what ran. Human-graded criteria"
    echo "    still need a read."
  elif [ "$fail" -eq 0 ]; then
    echo "=== ALL GREEN ($total/$total ran, machine assertions) — human-graded"
    echo "    criteria still need a read"
  else
    echo "=== FAILURES above"
  fi
  exit $fail
fi

file="$(resolve_scenario "$TARGET")" || {
  echo "no such scenario: $TARGET" >&2
  echo "known ids:" >&2
  for f in $(scenario_files); do echo "  $(meta "$f" SCENARIO_ID)" >&2; done
  exit 2
}
run_scenario "$file"
case $? in
  0) ;;
  3) echo "  (skipped — nothing ran)" ;;
  *) fail=1 ;;
esac
echo
echo "results: $RESULTS_ROOT/$RUN_STAMP"
exit $fail
