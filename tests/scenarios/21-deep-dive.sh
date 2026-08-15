# shellcheck shell=bash
SCENARIO_ID="deep-dive"
SCENARIO_TITLE="/privacy-counsel:deep-dive — depth with honest citations"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core web"
SCENARIO_TOOLS="Read,Glob,Grep,WebSearch,WebFetch"

scenario_run() {
  turn t1 "/privacy-counsel:deep-dive What does the EU AI Act require for general-purpose AI providers?"

  assert_words_min t1 900 "depth override lifts the caps"
  assert_match t1 "(\[model knowledge|\[web search|\[settled|\[verify)" "claims carry provenance tags"
  assert_match t1 "(general.purpose|GPAI)" "answers the question asked"

  criteria "Comprehensive and organized; still bottom-line-first, still no filler."
  criteria "Every legal claim carries a provenance tag; currency-sensitive points were checked against live sources."
  criteria "No invented citations — spot check two article numbers and one date against the actual regulation."
  criteria "Systemic-risk threshold and the GPAI obligations timeline are both addressed."
}
