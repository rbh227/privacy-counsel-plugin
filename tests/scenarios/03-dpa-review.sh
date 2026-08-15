# shellcheck shell=bash
SCENARIO_ID="dpa-review"
SCENARIO_TITLE="DPA review shape (header, severity ranking, minor-points line)"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"
# Deliberately no --add-dir: this scenario also proves the staged-degradation
# path. Without it the session cannot write to the state root, and the memo
# must still arrive inline, with the failed save disclosed — not silently
# dropped. Both halves are asserted below, because "it degraded gracefully"
# is indistinguishable from "it never tried to save" unless the disclosure is
# required.

scenario_run() {
  turn t1 "take a look at this DPA — we're the customer here, buying Meridian's analytics product for our client.

$(fixture dpa-meridian.md)"

  assert_match t1 "PRIVILEGED & CONFIDENTIAL" "work-product header present"
  assert_match t1 "ATTORNEY WORK PRODUCT" "work-product header is the full lawyer-role form"
  assert_match t1 "(🔴|🟠|🟡|critical|deal-?breaker|severity|must-fix)" "issues are severity-ranked"
  assert_match t1 "minor point(s)? (available )?on request" "minor points are offered, not dumped"
  assert_match t1 "(machine-learning|ML) (model|training)" "flags the §2.2 AI-training carve-out"
  assert_match t1 "(controller|processor)" "states the direction of the paper"
  assert_absent t1 "(run /privacy-counsel:setup|complete the setup interview|cold.?start)" "no setup prompt"

  # Staged degradation, machine-checked: nothing persisted, and the session
  # said so instead of pretending the save happened.
  assert_no_path "$STATE_DIR/matters" "no matter written when the state root is not granted"
  assert_match t1 "(could ?n[o']t save|unable to save|not saved|no write access|without write access|inline (below|instead)|deliver(ing|ed)? .*inline)" \
    "the blocked save is disclosed rather than silently dropped"

  criteria "Identifies whose paper it is and the client's posture (or asks, if genuinely ambiguous)."
  criteria "Prioritized issues only — typically ≤6 in the body; no 30-comment dump."
  criteria "The AI-training carve-out (§2.2) is treated as the headline, not buried mid-list."
  criteria "Each flagged issue carries a redline or a concrete ask, not just a complaint."
  criteria "Staged degradation: if the save to ~/.claude/privacy-counsel/ was blocked, it says so in one line and delivers the memo inline anyway."
}
