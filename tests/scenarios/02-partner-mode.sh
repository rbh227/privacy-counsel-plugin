# shellcheck shell=bash
SCENARIO_ID="partner-mode"
SCENARIO_TITLE="Partner-mode brevity, then depth escalation"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"

scenario_run() {
  turn t1 "We're buying a SaaS analytics product for a client. The vendor's DPA lets them use customer data in aggregated and de-identified form to train machine-learning models. How much should that worry me?"
  next t2 "Give me the full analysis."

  assert_words_max t1 550 "level 1 stays short"
  assert_absent t1 "(great question|happy to help|let me know if you|I hope this helps)" "no filler in level 1"
  assert_absent t1 "as an AI" "no assistant-voice disclaimer"
  assert_words_min t2 800 "full analysis lifts the cap"
  assert_words_grew t1 t2 2 "depth escalates substantially"

  criteria "t1 leads with a bottom line in one or two sentences, then at most 2–5 bullets, then stops."
  criteria "t1 ends in a recommendation or a clear view, not a menu of options."
  criteria "t1 does not explain what de-identification is — no basics for a senior lawyer."
  criteria "t2 is genuinely deeper (CCPA service-provider status, re-identification standard, model-survives-deletion), not the same content padded."
  criteria "t2 keeps bottom-line-first organization even with the caps lifted."
}
