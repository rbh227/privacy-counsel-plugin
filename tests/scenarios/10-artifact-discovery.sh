# shellcheck shell=bash
SCENARIO_ID="artifact-discovery"
SCENARIO_TITLE="Work product saved per matter and rediscovered in a later session"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core state"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"
# Writes to ~/.claude/privacy-counsel/. The harness pre-creates that directory
# and passes --add-dir; without BOTH, a headless session auto-denies the write
# (an --add-dir at a path that does not exist grants nothing).
SCENARIO_ADD_STATE=1

scenario_run() {
  # Session 1: open the matter, produce two pieces of work product.
  turn t1 "Open a matter for the Acme deal — slug acme."
  next t2 "Triage this for the acme matter and save the result: Acme wants to roll out AI-driven resume screening for EU job applicants."
  next t3 "Now review this DPA for the acme matter and save the review:

$(fixture dpa-meridian.md)"

  # Session 2: a FRESH session must rediscover session 1's work product.
  turn t4 "Run the policy sweep for the acme matter."

  assert_path "$STATE_DIR/matters/acme" "matter directory created"
  assert_path_nonempty "$STATE_DIR/matters/acme/outputs" "work product landed in the matter's outputs folder"
  # Match the distinctive CONTENT of the earlier work, never its doc type:
  # "DPA" appears in almost any answer this plugin gives, so the old pattern
  # passed whether or not anything was rediscovered.
  assert_match t3 "resume.screening" "the DPA review picked up the earlier triage"
  assert_match t4 "resume.screening" "a fresh session rediscovers the matter's prior work product"
  assert_path "$STATE_DIR/matters/acme/sweep-state.md" "sweep cursor lives in the matter, not globally"
  assert_file_absent_match "$STATE_DIR/state.md" "^Active matter:" \
    "state.md holds no active-matter pointer (active matter is session-scoped)"
  assert_no_path "$REPO_ROOT/matters" "nothing written into the plugin directory"

  criteria "t4 is a fresh session — it must NOT rely on conversation memory; check that it names the specific prior outputs it found."
  criteria "Outputs are named YYYY-MM-DD-<client>-<doctype>.md."
  criteria "Each saved output carries the work-product header."
  criteria "The sweep reports a real first-sweep (no cursor existed) rather than pretending to diff."
  criteria "Extension check, run by hand: open a second matter (slug beta) and sweep it — its first sweep must start from scratch, never inheriting acme's cursor."
}
