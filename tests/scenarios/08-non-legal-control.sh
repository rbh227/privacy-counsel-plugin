# shellcheck shell=bash
SCENARIO_ID="non-legal-control"
SCENARIO_TITLE="Control: a non-legal question does not misfire a legal skill"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"

scenario_run() {
  turn t1 "what's a good espresso machine?"

  assert_absent t1 "(GDPR|DPA|data processing|attorney work product|privilege|controller|processor)" \
    "no legal vocabulary bleeds in"
  assert_absent t1 "PRIVILEGED" "no work-product header on a coffee question"
  assert_absent t1 "(this is not legal advice|for attorney review)" "no legal caveats"
  assert_words_max t1 400 "stays concise"
  assert_match t1 "(espresso|grinder|machine)" "actually answers the question"

  criteria "Reads as a useful, opinionated answer from a smart colleague — brevity discipline carries over, legal machinery does not."
  criteria "Makes a recommendation rather than listing options without a view."
  criteria "No matter workspace is opened, no file is written."
}
