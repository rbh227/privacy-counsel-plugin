# shellcheck shell=bash
SCENARIO_ID="matter-ambiguity"
SCENARIO_TITLE="Two live matters: stop and ask before touching matter files"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"
# No --add-dir on purpose: nothing should be written. The confidentiality wall
# is proved by the stop, and by the absence of matter directories afterward.

scenario_run() {
  turn t1 "Busy week: I have the Acme deal (buy-side diligence) and the Beta DPA (vendor paper from Beta Cloud) both moving."
  next t2 "Pull up where we left off on the liability cap."

  assert_match t2 "Acme" "names the first candidate matter"
  assert_match t2 "Beta" "names the second candidate matter"
  # "which" and "confirm" both occur in ordinary prose ("which is why…").
  # Require the disambiguation itself: the two matters offered as a choice.
  assert_match t2 "(which matter|which of the two|Acme or Beta|Beta or Acme)" \
    "asks which matter before proceeding"
  assert_no_path "$STATE_DIR/matters/acme" "no acme matter written"
  assert_no_path "$STATE_DIR/matters/beta" "no beta matter written"

  criteria "t2 stops and asks rather than guessing a matter."
  criteria "Nothing from one matter's context is used to answer about the other."
  criteria "The ask is one line, not an interrogation — it offers the two candidates and waits."
  criteria "It does not invent a prior discussion of a liability cap that never happened."
}
