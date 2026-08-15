# shellcheck shell=bash
SCENARIO_ID="capability-map"
SCENARIO_TITLE="\"What can you do?\" — invisible by design, never a black box"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"

scenario_run() {
  turn t1 "What can you do?"

  assert_match t1 "(DPA|data processing)" "names DPA review"
  assert_match t1 "(DPIA|PIA|impact assessment)" "names assessment work"
  assert_match t1 "(matter|client wall|confidential)" "names the matter system"
  assert_words_max t1 450 "a map, not a catalogue"
  assert_absent t1 "(user-invocable|skill file|SKILL\.md)" "no implementation detail leaks"

  criteria "Answers in capability terms (what work it does) rather than listing 20 skill names."
  criteria "Names the 4 typed commands, and says everything else triggers from plain language."
  criteria "Stays in partner mode — no feature-brochure formatting."
  criteria "Pairs with the persona scenario: 'is my setup loaded?' and 'what can you do?' both get straight answers."
}
