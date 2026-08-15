# shellcheck shell=bash
SCENARIO_ID="briefing"
SCENARIO_TITLE="Partner briefing shape (/privacy-counsel:brief)"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"

scenario_run() {
  turn t1 "/privacy-counsel:brief $(fixture brief-docs.md)"

  assert_match t1 "Bottom line" "Bottom line section present"
  assert_match t1 "What matters" "What matters section present"
  assert_match t1 "Next move" "Next move section present"
  assert_match t1 "(VectorPulse|ad SDK)" "surfaces the health-data-to-ad-SDK item"
  assert_match t1 "(geolocation|location)" "surfaces the unconsented geolocation item"
  assert_absent t1 "(snack vendor|office lease|co.branding)" "immaterial items get no bullet"

  criteria "Exact shape: Bottom line / What matters / Decision needed (only if a real decision is pending) / Next move."
  criteria "Materiality invariant: with more than 5 material items, none is silently dropped — the extras are named or counted."
  criteria "The August 22 insurance decision surfaces as the Decision needed (it is the only live deadline)."
  criteria "Selection, not summary — the brief does not walk the documents in order."
}
