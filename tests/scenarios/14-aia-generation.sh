# shellcheck shell=bash
SCENARIO_ID="aia-generation"
SCENARIO_TITLE="AI impact assessment generated in the house format"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core state"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"
SCENARIO_ADD_STATE=1

scenario_run() {
  turn t1 "Generate the AI impact assessment for the acme resume-screening model. EU applicants, model trained on five years of the client's own hiring decisions, human recruiter reviews the shortlist."

  assert_match t1 "PRIVILEGED & CONFIDENTIAL" "work-product header present"
  assert_match t1 "(bias|discriminat|fairness)" "covers the bias dimension"
  assert_match t1 "(human oversight|human.in.the.loop|human review)" "covers human oversight"
  assert_path_nonempty "$STATE_DIR/matters/acme/outputs" "assessment saved to the matter"

  criteria "Starts at roughly 80% complete — sections pre-filled from the facts given, gaps marked, not a blank questionnaire."
  criteria "House format, not the upstream template verbatim; reviewer note block present."
  criteria "Picks up any earlier acme triage or inventory rather than re-deriving the facts."
  criteria "Training on the client's own historic hiring decisions is flagged as the proxy-discrimination risk."
}
