# shellcheck shell=bash
SCENARIO_ID="standing-correction"
SCENARIO_TITLE="An ordinary correction stays in-session; a standing one persists only on confirmation"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core state"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"
SCENARIO_ADD_STATE=1

# The rung-1-versus-rung-3 boundary, which is prose-enforced and therefore
# the easiest thing in the plugin to get wrong in either direction:
# over-persisting turns a one-off into a house position the partner never
# chose; never firing makes "make that my standard" a lie.

scenario_run() {
  # An ordinary correction — firm, specific, but scoped to this deal.
  turn t1 "Reviewing a vendor DPA for the Northwind deal. Use 30 days for deletion on termination here, not the usual 90."
  assert_no_path "$STATE_DIR/overrides.md" \
    "an ordinary in-session correction persisted nothing"

  # Now the standing signal. It must PROPOSE, showing the line, and wait.
  next t2 "Actually, make that my standard going forward."
  assert_no_path "$STATE_DIR/overrides.md" \
    "a standing signal alone still wrote nothing — it proposes first"
  # Keys may carry more than two segments — the live run wrote
  # dpa/deletion-on-termination/controller-side because one key could not
  # carry the controller/processor distinction. Match any depth.
  assert_match t2 "[a-z/-]+: *30" \
    "the proposal shows the exact key: value line it would write"
  assert_match t2 "(confirm|shall i|want me to|say the word|ok to)" \
    "the proposal asks before writing"

  next t3 "Yes."
  assert_file_match "$STATE_DIR/overrides.md" "^[a-z/-]+: *30" \
    "confirmation wrote the keyed position"

  # A fresh session inherits it.
  turn t4 "What's our deletion-on-termination position for a vendor DPA?"
  assert_match t4 "30 ?(d|days)" "a fresh session applies the persisted standard"
  assert_match t4 "(override|standard|house position|you set|practice-level)" \
    "names the rung it applied"

  criteria "t1 applied 30 days for the Northwind matter without offering to persist — an unprompted offer on every correction is its own failure."
  criteria "t2 showed the line it would write and stopped; it did not write and then report."
  criteria "t4 does not re-derive 90 days from the playbook — the file wins over the default."
  criteria "Nothing in the run wrote a matter directory for Northwind: this was a position, not matter work."
}
