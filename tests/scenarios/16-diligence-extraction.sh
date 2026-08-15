# shellcheck shell=bash
SCENARIO_ID="diligence-extraction"
SCENARIO_TITLE="Diligence issues extracted by category and materiality"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core state"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"
SCENARIO_ADD_STATE=1

scenario_run() {
  turn t1 "Extract the diligence issues from these data-room documents for the acme matter:

$(fixture brief-docs.md)"

  assert_match t1 "(material|materiality)" "issues carry a materiality grade"
  assert_match t1 "(VectorPulse|ad SDK)" "catches the health-data-to-ad-SDK issue"
  assert_match t1 "(BAA|hospital)" "catches the missing executed BAA"
  assert_path_nonempty "$STATE_DIR/matters/acme/outputs" "extraction saved to the matter"

  criteria "Findings arrive structured by category (privacy, security, contract, governance), each with a materiality grade and a source pointer."
  criteria "Immaterial noise (office lease, snack vendor) is excluded or explicitly parked."
  criteria "Every issue traces to a document — no issue asserted without a source."
  criteria "Hands off to deal-judgment for consequences rather than inventing its own remedies."
}
