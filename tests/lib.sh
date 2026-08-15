#!/bin/bash
# Shared helpers for privacy-counsel headless scenario runs.
#
# Sourced by tests/run.sh; scenario files in tests/scenarios/ call the
# turn/assert helpers defined here. Bash 3.2 compatible (macOS system bash) —
# no associative arrays, no `${arr[@]}` expansion under `set -u` without a
# guard.
#
# The seam under test is a real `claude -p` session: the SessionStart hook
# fires exactly as it does in production, so what the harness grades is
# plugin behavior, never plugin source.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
FIXTURES_DIR="$TESTS_DIR/fixtures"
RESULTS_ROOT="${PC_RESULTS_ROOT:-$TESTS_DIR/.results}"

# ------------------------------------------------------------ state isolation
#
# The plugin resolves its state root from PRIVACY_COUNSEL_HOME, falling back to
# ~/.claude/privacy-counsel — which holds REAL client matters. The harness
# therefore always redirects that root to a per-run directory it created
# itself. Three things follow:
#   - a scenario can never read, write, or delete real work;
#   - every run starts from an empty root, so runs are idempotent and a
#     scenario cannot pass on an artifact a previous run left behind;
#   - there is nothing to reset, which is why --reset-state is gone. It used
#     to `rm -rf` the slugs "acme beta general" out of the production root,
#     and "general" is the practice-level default — a reset could delete a
#     partner's real practice-level state.
PRODUCTION_STATE_DIR="$HOME/.claude/privacy-counsel"

# init_state_root — called by run.sh once RUN_STAMP exists.
init_state_root() {
  STATE_DIR="${PC_STATE_DIR:-$RESULTS_ROOT/$RUN_STAMP/state}"
  case "${STATE_DIR%/}" in
    "$PRODUCTION_STATE_DIR")
      _die "refusing to run against the production state root ($STATE_DIR)" ;;
  esac
  mkdir -p "$STATE_DIR" || _die "cannot create state root: $STATE_DIR"
  export PRIVACY_COUNSEL_HOME="$STATE_DIR"
}

# Matter slugs the scenarios create. Collisions with a partner's real matter
# names no longer matter — the root is per-run and disposable.
TEST_MATTER_SLUGS="acme beta general"

# Per-turn wall-clock ceiling. A wedged session should fail the run, not hang it.
TURN_TIMEOUT="${PC_TURN_TIMEOUT:-900}"

# Cumulative cost ceiling for a whole run, in USD, summed from each turn's
# total_cost_usd. A live-model battery with no ceiling is an open tab.
MAX_COST_USD="${PC_MAX_COST_USD:-10}"
RUN_COST_USD=0

# Model for every scenario session. Pinned rather than inherited: an
# unpinned run grades whatever the user's default happens to be that day,
# so a result could change without the branch changing. Override to
# re-baseline deliberately, never by accident.
PC_MODEL="${PC_MODEL:-opus}"

# Tool grant for a scenario that does not override it. Deliberately narrow:
# no WebSearch/WebFetch (web-tagged scenarios add those themselves), no
# unscoped Bash.
DEFAULT_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"

CLAUDE_BIN="${PC_CLAUDE_BIN:-}"
if [ -z "$CLAUDE_BIN" ]; then
  CLAUDE_BIN="$(command -v claude 2>/dev/null)"
fi
if [ -z "$CLAUDE_BIN" ] && [ -x "$HOME/.local/bin/claude" ]; then
  CLAUDE_BIN="$HOME/.local/bin/claude"
fi

# ----------------------------------------------------------- plugin binding
#
# Without --plugin-dir, a headless session loads whatever privacy-counsel is
# INSTALLED on the machine. On a dev box that install points at the main
# worktree, so scenarios run from any other worktree silently grade a
# different tree — a green run that says nothing about the branch. So: load
# REPO_ROOT explicitly, and disable every installed copy so the hook cannot
# fire twice.
#
# --settings is a claim, not a proof. preflight() below is the proof: it asks
# a live session which paths its status block reports and fails the run if
# they are not this tree.
_harness_settings() {
  python3 - <<'PY'
import json, os
disabled = {}
try:
    d = json.load(open(os.path.expanduser("~/.claude/plugins/installed_plugins.json")))
    for key in d.get("plugins", {}):
        if key.split("@", 1)[0] == "privacy-counsel":
            disabled[key] = False
except Exception:
    pass
print(json.dumps({"enabledPlugins": disabled}) if disabled else "")
PY
}
HARNESS_SETTINGS="$(_harness_settings 2>/dev/null)"

# ---------------------------------------------------------------- utilities

_die() { echo "harness error: $*" >&2; exit 2; }

# _timeout <seconds> <cmd...> — SIGALRM survives exec, so the alarm fires
# against the exec'd process. Degrades to no timeout if perl is absent.
_timeout() {
  local secs="$1"; shift
  if command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
  else
    "$@"
  fi
}

fixture() {
  local name="$1"
  [ -f "$FIXTURES_DIR/$name" ] || _die "missing fixture: $name"
  cat "$FIXTURES_DIR/$name"
}

# ------------------------------------------------------------------- turns
#
# turn <label> <prompt>   — fresh session (hook fires)
# next <label> <prompt>   — resume the previous turn's session
#
# Both write <label>.json (raw result envelope), <label>.txt (assistant text),
# <label>.err (stderr) and <label>.prompt.txt into the scenario result dir,
# and set LAST_SID.

turn() { _turn "$1" "$2" ""; }

# next resumes the previous turn's session. A missing session id is a hard
# stop, never a silent fresh session: the whole point of a resume turn is that
# the earlier context is present, and grading turn 2 of a two-turn scenario
# against a blank session is worse than failing.
next() {
  if [ -z "${LAST_SID:-}" ]; then
    SCENARIO_ABORTED=1
    _fail "turn $1: cannot resume — the previous turn returned no session id"
    return 1
  fi
  _turn "$1" "$2" "$LAST_SID"
}

# _add_cost <usd> — accumulate spend across scenarios (each runs in its own
# subshell, so the running total lives in a file) and stop the run at the cap.
_add_cost() {
  local file="$RESULTS_ROOT/$RUN_STAMP/cost.tsv" total
  printf '%s\t%s\n' "${SCENARIO_ID:-preflight}" "$1" >> "$file"
  total="$(awk -F'\t' '{ s += $2 } END { printf "%.4f", s }' "$file")"
  if awk -v t="$total" -v cap="$MAX_COST_USD" 'BEGIN { exit !(t > cap) }'; then
    _die "run cost \$$total exceeded the \$$MAX_COST_USD cap (raise PC_MAX_COST_USD to continue)"
  fi
}

_turn() {
  local label="$1" prompt="$2" sid="$3"
  local out="$RESULT_DIR/$label"
  local rc t0 elapsed parsed newsid cost d

  [ -n "$CLAUDE_BIN" ] || _die "claude binary not found (set PC_CLAUDE_BIN)"

  # A scenario that lost a turn cannot be graded from here on: later turns
  # would resume from the wrong point or run against missing context, and
  # every one of them costs real tokens to be wrong.
  if [ "${SCENARIO_ABORTED:-0}" = "1" ]; then
    _fail "turn $label: skipped — an earlier turn in this scenario failed"
    return 1
  fi

  # $1..$3 are already captured above; reuse the positional list as the argv
  # builder so this stays Bash 3.2 safe (no empty-array expansion under -u).
  set -- -p --output-format json --allowedTools "$SCENARIO_TOOLS" \
         --model "$PC_MODEL" --plugin-dir "$REPO_ROOT"
  if [ -n "$HARNESS_SETTINGS" ]; then
    set -- "$@" --settings "$HARNESS_SETTINGS"
  fi
  if [ "$SCENARIO_ADD_STATE" = "1" ]; then
    mkdir -p "$STATE_DIR"
    set -- "$@" --add-dir "$STATE_DIR"
  fi
  for d in $SCENARIO_ADD_DIRS; do
    mkdir -p "$d"
    set -- "$@" --add-dir "$d"
  done
  if [ -n "$sid" ]; then
    set -- "$@" --resume "$sid"
  fi

  printf '%s' "$prompt" > "$out.prompt.txt"
  printf '  turn %-4s %s ... ' "$label" "$([ -n "$sid" ] && echo resume || echo fresh)"

  t0=$(date +%s)
  # The prompt goes on stdin: the variadic --allowedTools flag swallows a
  # positional prompt argument.
  ( cd "$NEUTRAL_CWD" && printf '%s' "$prompt" | _timeout "$TURN_TIMEOUT" "$CLAUDE_BIN" "$@" ) \
    > "$out.json" 2> "$out.err"
  rc=$?
  elapsed=$(( $(date +%s) - t0 ))

  if [ $rc -ne 0 ]; then
    printf 'ERROR (exit %s, %ss)\n' "$rc" "$elapsed"
    _fail "turn $label: claude exited $rc — see $out.err"
    SCENARIO_ABORTED=1
    LAST_SID=""
    return 1
  fi

  # Prints "<session-id>\t<cost-usd>". A blank session id is a failure, not a
  # success with an empty string — the caller would otherwise resume nothing.
  parsed="$(python3 - "$out" <<'PY'
import json, sys
out = sys.argv[1]
try:
    d = json.load(open(out + ".json"))
except Exception as e:
    sys.stderr.write("PARSE_FAIL %s\n" % e)
    sys.exit(1)
open(out + ".txt", "w").write(d.get("result", "") or "")
if d.get("is_error"):
    sys.stderr.write("IS_ERROR\n")
    sys.exit(3)
sid = d.get("session_id") or ""
if not sid:
    sys.stderr.write("NO_SESSION_ID\n")
    sys.exit(4)
print("%s\t%s" % (sid, d.get("total_cost_usd", 0) or 0))
PY
)"
  rc=$?
  if [ $rc -ne 0 ]; then
    printf 'BAD RESULT (%ss)\n' "$elapsed"
    _fail "turn $label: unparseable, is_error, or no session id — see $out.json"
    SCENARIO_ABORTED=1
    LAST_SID=""
    return 1
  fi

  newsid="${parsed%%	*}"
  cost="${parsed##*	}"
  LAST_SID="$newsid"
  _add_cost "$cost"
  printf 'ok (%ss, %s words, $%s)\n' \
    "$elapsed" "$(wc -w < "$out.txt" | tr -d ' ')" "$cost"
  return 0
}

# ------------------------------------------------------------------ preflight
#
# Proves, with a live session, that scenarios grade THIS tree and THIS state
# root before any scenario is graded. The hook prints both paths in its status
# block, so one turn is enough to catch: the installed plugin winning over
# --plugin-dir, a stale --settings key, a hook that failed to fire, and a
# state root that still points at the partner's real matters.
preflight() {
  SCENARIO_ID="preflight"
  SCENARIO_TOOLS="Read"
  SCENARIO_ADD_STATE=0
  SCENARIO_ADD_DIRS=""
  SCENARIO_ABORTED=0
  ASSERT_PASS=0
  ASSERT_FAIL=0
  LAST_SID=""
  RESULT_DIR="$RESULTS_ROOT/$RUN_STAMP/preflight"
  NEUTRAL_CWD="$(mktemp -d "${TMPDIR:-/tmp}/privacy-counsel-preflight.XXXXXX")"
  mkdir -p "$RESULT_DIR"

  echo "=== preflight — is the session loading the tree under test?"
  turn pf 'Quote two lines from your session component status block verbatim: the "Practice playbook:" line and the "Mutable state root:" line. Output nothing else.'

  assert_match pf "$(printf '%s' "$REPO_ROOT" | sed 's/[.[\*^$]/\\&/g')" \
    "session loaded the plugin at REPO_ROOT ($REPO_ROOT)"
  assert_match pf "$(printf '%s' "$STATE_DIR" | sed 's/[.[\*^$]/\\&/g')" \
    "session state root is the harness root ($STATE_DIR)"
  assert_absent pf "$(printf '%s' "$PRODUCTION_STATE_DIR" | sed 's/[.[\*^$]/\\&/g')/?\$" \
    "session state root is not the production root"

  rm -rf "$NEUTRAL_CWD"
  if [ "$ASSERT_FAIL" -ne 0 ]; then
    echo "  == preflight FAILED — every scenario below would grade the wrong tree" >&2
    return 1
  fi
  echo "  == preflight ok"
  return 0
}

# -------------------------------------------------------------- assertions
#
# Every assert_* prints one PASS/FAIL line and moves the scenario counters.
# Assertions are machine-checkable only; anything needing judgment goes
# through criteria() and is graded by a human against the saved transcript.

_pass() { ASSERT_PASS=$((ASSERT_PASS + 1)); printf '  PASS  %s\n' "$1"; }
_fail() { ASSERT_FAIL=$((ASSERT_FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

_transcript() { echo "$RESULT_DIR/$1.txt"; }

_require_transcript() {
  if [ ! -f "$RESULT_DIR/$1.txt" ]; then
    _fail "$2  [no transcript for turn $1]"
    return 1
  fi
  return 0
}

# _grep_rc <regex> <file> — 0 match, 1 no match, 2 the regex itself is broken.
#
# That third case is why this exists. grep exits 2 on an invalid pattern, and
# every negative assertion here used to read "non-zero" as "absent" — so a
# typo'd regex reported PASS. A real one shipped: `(|a|b)` (empty alternative)
# printed "grep: empty (sub)expression" and passed. An assertion that cannot
# fail is worse than no assertion, because it reads as coverage.
_grep_rc() {
  grep -qiE -- "$1" "$2" 2>/dev/null
  return $?
}

# assert_match <turn-label> <extended-regex> <description>
assert_match() {
  _require_transcript "$1" "$3" || return 1
  _grep_rc "$2" "$(_transcript "$1")"
  case $? in
    0) _pass "$3" ;;
    1) _fail "$3  [$1: no match for /$2/]" ;;
    *) _fail "$3  [INVALID REGEX /$2/ — fix the assertion]" ;;
  esac
}

# assert_absent <turn-label> <extended-regex> <description>
assert_absent() {
  _require_transcript "$1" "$3" || return 1
  _grep_rc "$2" "$(_transcript "$1")"
  case $? in
    0) _fail "$3  [$1: matched /$2/ — $(grep -ioE -- "$2" "$(_transcript "$1")" | head -1)]" ;;
    1) _pass "$3" ;;
    *) _fail "$3  [INVALID REGEX /$2/ — fix the assertion]" ;;
  esac
}

_head_words() {
  tr '\n' ' ' < "$(_transcript "$1")" \
    | awk -v n="$2" '{ for (i = 1; i <= n && i <= NF; i++) printf "%s ", $i }'
}

# assert_head_match <turn-label> <n-words> <regex> <description>
# "verdict first" / "draft first" style checks: the thing must appear in the
# opening N words, not buried after three paragraphs of throat-clearing.
assert_head_match() {
  _require_transcript "$1" "$4" || return 1
  _head_words "$1" "$2" | grep -qiE -- "$3" 2>/dev/null
  case $? in
    0) _pass "$4" ;;
    1) _fail "$4  [$1: /$3/ not in first $2 words]" ;;
    *) _fail "$4  [INVALID REGEX /$3/ — fix the assertion]" ;;
  esac
}

# assert_head_absent <turn-label> <n-words> <regex> <description>
assert_head_absent() {
  _require_transcript "$1" "$4" || return 1
  _head_words "$1" "$2" | grep -qiE -- "$3" 2>/dev/null
  case $? in
    0) _fail "$4  [$1: /$3/ found in first $2 words]" ;;
    1) _pass "$4" ;;
    *) _fail "$4  [INVALID REGEX /$3/ — fix the assertion]" ;;
  esac
}

_words() { wc -w < "$(_transcript "$1")" | tr -d ' '; }

# assert_words_max <turn-label> <n> <description>
assert_words_max() {
  _require_transcript "$1" "$3" || return 1
  local w; w="$(_words "$1")"
  if [ "$w" -le "$2" ]; then _pass "$3 ($w words)"; else _fail "$3  [$1: $w words > $2]"; fi
}

# assert_words_min <turn-label> <n> <description>
assert_words_min() {
  _require_transcript "$1" "$3" || return 1
  local w; w="$(_words "$1")"
  if [ "$w" -ge "$2" ]; then _pass "$3 ($w words)"; else _fail "$3  [$1: $w words < $2]"; fi
}

# assert_words_grew <short-label> <long-label> <integer-factor> <description>
assert_words_grew() {
  _require_transcript "$1" "$4" || return 1
  _require_transcript "$2" "$4" || return 1
  local a b
  a="$(_words "$1")"; b="$(_words "$2")"
  if [ "$a" -gt 0 ] && [ "$b" -ge $((a * $3)) ]; then
    _pass "$4 ($a → $b words)"
  else
    _fail "$4  [$a → $b words, wanted ≥ ${3}x]"
  fi
}

# assert_path <path> <description>
assert_path() {
  if [ -e "$1" ]; then _pass "$2"; else _fail "$2  [missing: $1]"; fi
}

# assert_no_path <path> <description>
assert_no_path() {
  if [ -e "$1" ]; then _fail "$2  [exists: $1]"; else _pass "$2"; fi
}

# assert_path_nonempty <dir> <description> — at least one entry in the dir
assert_path_nonempty() {
  if [ -d "$1" ] && [ -n "$(ls -A "$1" 2>/dev/null)" ]; then
    _pass "$2 ($(ls -A "$1" | tr '\n' ' '))"
  else
    _fail "$2  [empty or missing: $1]"
  fi
}

# assert_file_match <path> <regex> <description>
# Passes only when the file exists AND contains the pattern. Use for state
# the plugin wrote: a transcript claiming a value proves nothing about what
# landed on disk.
assert_file_match() {
  if [ ! -f "$1" ]; then
    _fail "$3  [missing: $1]"
    return
  fi
  _grep_rc "$2" "$1"
  case $? in
    0) _pass "$3" ;;
    1) _fail "$3  [$1: no match for /$2/]" ;;
    *) _fail "$3  [INVALID REGEX /$2/ — fix the assertion]" ;;
  esac
}

# assert_file_absent_match <path> <regex> <description>
# Passes when the file does not exist OR does not contain the pattern.
assert_file_absent_match() {
  if [ ! -f "$1" ]; then
    _pass "$3"
    return
  fi
  _grep_rc "$2" "$1"
  case $? in
    0) _fail "$3  [$1 contains /$2/]" ;;
    1) _pass "$3" ;;
    *) _fail "$3  [INVALID REGEX /$2/ — fix the assertion]" ;;
  esac
}

# ---------------------------------------------------------- human grading
#
# criteria <text> — a pass criterion that needs a human eye. Printed after the
# machine assertions next to the transcript path. Never fails the run: a
# harness that pretends to grade judgment automatically is lying.

criteria() { CRITERIA_LINES="${CRITERIA_LINES}
  - $1"; }
