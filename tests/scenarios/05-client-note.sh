# shellcheck shell=bash
SCENARIO_ID="client-note"
SCENARIO_TITLE="Client note: the draft comes first"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core"
SCENARIO_TOOLS="Read,Glob,Grep"

scenario_run() {
  turn t1 "Draft a short note to the client saying we're comfortable proceeding with the Meridian analytics DPA, subject to two changes: 48-hour breach notice, and deletion of the clause letting Meridian train models on de-identified customer data."

  assert_head_absent t1 40 "(here.s a|here is a|below is|I.ve drafted|I have drafted|I.ll draft|sure[,!]|of course)" \
    "no preamble — the draft is the answer"
  assert_match t1 "(48.hour|48 hour)" "carries the first instructed change"
  assert_match t1 "(train|training|model)" "carries the second instructed change"
  assert_words_max t1 600 "deliverable is complete but not padded"
  assert_absent t1 "(as an AI|I hope this helps|let me know if you.d like me to)" "no assistant voice"

  criteria "The note itself opens the response — a subject line or salutation within the first few lines."
  criteria "House register: crisp declarative openings, no AI clichés, no hedging stack."
  criteria "Complete despite brevity mode (deliverable exemption applies)."
  criteria "Any explanation appears AFTER the draft and only if a material qualification exists."
  criteria "Signature block is generic or bracketed — never a real person's name."
}
