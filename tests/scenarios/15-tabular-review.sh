# shellcheck shell=bash
SCENARIO_ID="tabular-review"
SCENARIO_TITLE="Tabular review over a folder of contracts (anti-fabrication intact)"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"

# The three documents are chosen so every not-found state has to be produced
# honestly at least once:
#   meridian  — audit right present but reports-only; explicit AI-training carve-out
#   northwind — no audit clause AT ALL, and no AI-training language (not_present)
#   calder    — "improve the Services generally" and a website subprocessor list,
#               neither of which resolves cleanly either way (unclear)
# An earlier version of this scenario described these documents in a comment
# and never staged them, so the session had an empty folder and could only
# stop or invent. Staging them is what makes the assertions mean anything.

scenario_run() {
  cp "$FIXTURES_DIR/dpa-meridian.md"  "$NEUTRAL_CWD/dpa-meridian.md"
  cp "$FIXTURES_DIR/dpa-northwind.md" "$NEUTRAL_CWD/dpa-northwind.md"
  cp "$FIXTURES_DIR/dpa-calder.md"    "$NEUTRAL_CWD/dpa-calder.md"

  turn t1 "Run a tabular review over the DPAs in this folder. Columns: counterparty, breach-notice window, subprocessor objection right, audit right, AI-training carve-out."

  # One row per document — a review that silently drops a document is the
  # failure this catches.
  assert_match t1 "Meridian" "Meridian has a row"
  assert_match t1 "Northwind" "Northwind has a row"
  assert_match t1 "Calder" "Calder has a row"

  # Values that are actually in the documents, so a fabricated table fails.
  assert_match t1 "72" "reads Meridian's 72-hour breach window from the text"
  assert_match t1 "48" "reads Northwind's 48-hour breach window from the text"

  assert_match t1 "(not.?present|not found|not addressed|silent|absent)" \
    "produces an honest not-found state for the missing audit clause"
  assert_match t1 "(unclear|ambiguous|needs.?review)" \
    "distinguishes ambiguous drafting from absent drafting"
  assert_absent t1 "plugins/config/claude-for-legal" "no upstream config path leaks"

  criteria "Every populated cell quotes its source verbatim — spot check three char-for-char against the staged files. Any paraphrase in a quote cell is a hard fail: this machinery is load-bearing and must not have been weakened by the overlay."
  criteria "Northwind's audit right reads not_present (the document has no audit clause), NOT unclear — it was read and the clause is genuinely absent."
  criteria "Calder's AI-training and subprocessor-objection cells read unclear rather than yes or no — 'improve the Services generally' and a website list resolve neither way."
  criteria "No column is invented, and no row is fabricated for a document that is not in the folder."
  criteria "Output is markdown plus CSV — it must not claim to have written a .xlsx this session could not produce."
}
