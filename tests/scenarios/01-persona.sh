# shellcheck shell=bash
SCENARIO_ID="persona"
SCENARIO_TITLE="Persona + self-identification"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"

scenario_run() {
  turn t1 "Is my setup loaded? Which persona are you running?"

  assert_match t1 "privacy" "names the privacy practice"
  assert_match t1 "partner" "names the partner persona"
  assert_match t1 "(large firm|outside counsel)" "names the firm posture"
  assert_match t1 "\bEU\b" "names the EU half of the default footprint"
  assert_match t1 "(\bUS\b|U\.S\.|United States)" "names the US half of the default footprint"
  assert_words_max t1 140 "answers in a line or two, not a page"
  assert_absent t1 "(great question|happy to help|let me know if you)" "no filler"

  criteria "Confirms the plugin/profile IS active — an unhedged yes, not 'I don't have information about plugins'."
  criteria "Does not enumerate the hidden skills as user-invocable commands."
  criteria "Register is a colleague answering, not a product describing itself."
}
