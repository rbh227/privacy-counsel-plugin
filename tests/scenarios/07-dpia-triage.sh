# shellcheck shell=bash
SCENARIO_ID="dpia-triage"
SCENARIO_TITLE="Use-case triage: DPIA classification"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"

scenario_run() {
  turn t1 "Does this feature need a DPIA? We're adding behavioral ad targeting for EU users."

  assert_match t1 "DPIA" "answers in DPIA terms"
  # Not "yes": a bare yes matches "yes, but it's hard to say" and even a
  # negative answer that happens to contain the word. The classification has
  # to be stated as one.
  assert_match t1 "(DPIA is (likely )?(mandatory|required)|(mandatory|required) DPIA|needs? a DPIA|triggers? [^.]{0,30}DPIA)" \
    "reaches a classification, not a maybe"
  assert_match t1 "(Art(icle)?\.? ?35|Article 35)" "grounds it in GDPR Art. 35"
  assert_absent t1 "(run /privacy-counsel:setup|complete the setup interview|cold.?start)" "no setup prompt"
  assert_absent t1 "(a DPIA is a|DPIA stands for|Data Protection Impact Assessment \(DPIA\) is)" \
    "does not explain what a DPIA is"

  criteria "Classification is explicit (DPIA MANDATORY / recommended / not required) and correct — behavioral ad targeting of EU users is the textbook Art. 35 case."
  criteria "Assumptions are stated where facts are missing (scale, lawful basis, whether a policy exists)."
  criteria "Currency-sensitive claims carry a source tag; no invented pinpoint citations."
  criteria "Names the next step (who runs the DPIA, what blocks launch), not just the classification."
}
