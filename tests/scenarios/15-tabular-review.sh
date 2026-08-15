# shellcheck shell=bash
SCENARIO_ID="tabular-review"
SCENARIO_TITLE="Tabular review over a folder of contracts (anti-fabrication intact)"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"

scenario_run() {
  # The runner's neutral cwd doubles as the document folder; the scenario
  # stages three short DPAs there, one of which is deliberately silent on the
  # audit right so a not-found state has to be produced honestly.
  turn t1 "Run a tabular review over the DPAs in this folder. Columns: counterparty, breach-notice window, subprocessor objection right, audit right, AI-training carve-out."

  assert_match t1 "(not found|not addressed|silent)" "produces an honest not-found state"
  assert_absent t1 "plugins/config/claude-for-legal" "no upstream config path leaks"

  criteria "One row per document; every populated cell quotes its source verbatim."
  criteria "The three not-found states are distinguished (absent from the document / present but ambiguous / document unreadable) — not collapsed into one N/A."
  criteria "Spot check three cells char-for-char against the source documents. Any paraphrase in a quote cell is a hard fail — this machinery is load-bearing and must not have been weakened by the overlay."
  criteria "No column is invented, and no row is fabricated for a document that is not there."
  criteria "Excel/Sheets output degrades gracefully to markdown rather than erroring."
}
