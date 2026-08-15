# shellcheck shell=bash
SCENARIO_ID="amendment-history"
SCENARIO_TITLE="Contract amendment history traced clause by clause"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"

scenario_run() {
  # Stages a base MSA plus two amendments in the neutral cwd, one of which
  # silently re-amends a clause the other already changed.
  turn t1 "Trace the amendment history of this MSA — what changed since 2023, clause by clause?"

  assert_match t1 "(amendment|amended)" "answers in amendment terms"
  assert_absent t1 "plugins/config/claude-for-legal" "no upstream config path leaks"

  criteria "Per-clause history: original text, each amendment that touched it, and the operative current text."
  criteria "The doubly-amended clause shows both changes in order, not just the latest."
  criteria "Clauses untouched by any amendment are stated as unchanged rather than omitted silently."
  criteria "Quotes are verbatim; no reconstructed 'as amended' text that appears in no document."
}
