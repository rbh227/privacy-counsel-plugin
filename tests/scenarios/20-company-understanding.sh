# shellcheck shell=bash
SCENARIO_ID="company-understanding"
SCENARIO_TITLE="Company research through the privacy/deal lens"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core web"
SCENARIO_TOOLS="Read,Glob,Grep,WebSearch,WebFetch"

scenario_run() {
  turn t1 "What does Snowplow actually do?"

  assert_match t1 "Bottom line" "leads with a bottom line"
  assert_match t1 "(data|analytics|event)" "gets the business right"
  assert_absent t1 "(founded in|was founded|founding story|the company was started)" "no founding story"
  assert_words_max t1 700 "stays in partner mode"

  criteria "Labeled bullets: what it does / customers / business model / data-AI angle / legal relevance."
  criteria "Material claims are sourced with a provenance tag ([web search — verify] or better)."
  criteria "The legal-relevance bullet is the point of the answer, not an afterthought."
  criteria "No invented customer names, funding figures, or revenue numbers."
}
