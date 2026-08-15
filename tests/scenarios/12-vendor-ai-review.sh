# shellcheck shell=bash
SCENARIO_ID="vendor-ai-review"
SCENARIO_TITLE="Vendor AI terms reviewed against the governance playbook"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"

scenario_run() {
  turn t1 "Review this AI addendum from a vendor. They want the right to use our prompts and outputs to fine-tune their foundation model, they reserve the right to change the underlying model with 30 days' notice, and AI-related claims sit inside the general liability cap."

  assert_match t1 "PRIVILEGED & CONFIDENTIAL" "work-product header present"
  assert_match t1 "(training|fine-?tun)" "flags the training-on-data position"
  assert_match t1 "(model change|model version|substitut)" "flags the model-change right"
  assert_match t1 "(liability|cap)" "flags the liability treatment"
  assert_absent t1 "plugins/config/claude-for-legal" "no upstream config path leaks into the output"
  assert_absent t1 "(launch-review|ai-tool-handoff|legal-builder-hub|customize)" \
    "no references to unshipped upstream skills"

  criteria "Reads from THIS plugin's playbook, not an upstream ai-governance config file — it never asks the user to run an upstream setup."
  criteria "Training-on-data is treated as the deal-breaker position, ranked first."
  criteria "Output obeys partner mode and the work-product header rules like a native skill."
  criteria "Matter operations (if any) go through our matter system at ~/.claude/privacy-counsel/."
}
