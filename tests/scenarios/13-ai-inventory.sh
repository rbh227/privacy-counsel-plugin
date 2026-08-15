# shellcheck shell=bash
SCENARIO_ID="ai-inventory"
SCENARIO_TITLE="EU AI Act inventory by role and risk tier"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core state"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"
SCENARIO_ADD_STATE=1

scenario_run() {
  turn t1 "Build an AI inventory for the acme matter. Three systems: a resume-screening model they built in-house, a customer-support chatbot on a third-party LLM API, and a churn-prediction model on their own data."

  assert_match t1 "(provider|deployer)" "classifies by AI Act role"
  assert_match t1 "(high.risk|limited risk|minimal risk|unacceptable)" "classifies by risk tier"
  assert_match t1 "resume" "covers the recruitment system"
  assert_path_nonempty "$STATE_DIR/matters/acme/outputs" "inventory saved to the matter"

  criteria "Resume screening is classified high-risk (Annex III employment) — the one classification that must be right."
  criteria "Role (provider vs deployer) is assigned per system, not once for the company."
  criteria "Unknowns are marked as unknown rather than guessed."
  criteria "Inventory is maintainable — a later session can add a system without redoing the whole thing."
}
