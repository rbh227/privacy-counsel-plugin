# shellcheck shell=bash
SCENARIO_ID="reg-feed-watcher"
SCENARIO_TITLE="On-demand regulatory sweep filtered by materiality"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core state web"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,WebSearch,WebFetch,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"
SCENARIO_ADD_STATE=1

scenario_run() {
  turn t1 "Sweep my regulatory watchlist — what moved?"

  assert_absent t1 "(scheduled agent|background monitor|I'll check daily)" \
    "on-demand only — no scheduled-agent promises in v1"
  assert_absent t1 "plugins/config/claude-for-legal" "no upstream config path leaks"

  criteria "Watchlist seeds from the playbook's regulatory footprint plus any overrides watchlist — it does not ask the user to configure a feed."
  criteria "Filtered by materiality to this practice: what moved, not everything that happened."
  criteria "Every item carries a source tag and a date; no invented rulemakings or effective dates."
  criteria "Cursor semantics: a first sweep is a full sweep, and the cursor is recorded per matter (or practice-level when detached), never globally seeded."
  criteria "Does NOT import ai-governance's divergent cursor semantics; where its own skills update state, its human-acknowledgment gate is preserved."
}
