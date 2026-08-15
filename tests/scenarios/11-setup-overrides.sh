# shellcheck shell=bash
SCENARIO_ID="setup-overrides"
SCENARIO_TITLE="Setup writes durable overrides; a new session honors them"
SCENARIO_STATUS="active"
SCENARIO_TAGS="core state"
SCENARIO_TOOLS="Read,Write,Edit,Glob,Grep,Bash(mkdir:*),Bash(ls:*),Bash(cat:*)"
SCENARIO_ADD_STATE=1

# Canonical keys the interview can write. Questions 5, 6 and 8 go unanswered
# below, so their keys must NOT appear — a skipped question that writes its
# own default is the failure this list exists to catch, and it is invisible
# afterward because the file then reads like a deliberate choice.
SKIPPED_KEYS="dpa/liability-cap transfers/mechanism outputs/save-by-default outputs/header"

scenario_run() {
  # A key no version of setup knows about. A re-run must leave it alone.
  mkdir -p "$STATE_DIR"
  cat > "$STATE_DIR/overrides.md" <<'SEED'
<!-- hand-written before setup ever ran -->

## Overrides

custom/legacy-position: hand-written, must survive a setup re-run
SEED

  turn t1 "/privacy-counsel:setup"
  next t2 "Controller-side, mostly EU clients — keep the US in scope too. Heavy M&A diligence mix. My standard breach notice is 48 hours, not 72. Watchlist: EU AI Act, CPRA, Colorado AI Act."
  next t3 "Yes, write it."

  # Re-run changing ONE answer. Everything else must survive byte-for-byte.
  turn t4 "/privacy-counsel:setup"
  next t5 "Only change the breach notice window — make it 24 hours from awareness. Leave everything else."
  next t6 "Confirmed."

  # A fresh session, no conversation memory, must negotiate from the file.
  turn t7 "What's my standard breach-notice window for a vendor DPA?"

  assert_path "$STATE_DIR/overrides.md" "overrides written outside the plugin directory"
  assert_no_path "$REPO_ROOT/overrides.md" "nothing written into the plugin install directory"

  # Keyed format, not prose: the precedence contract compares sources by key.
  assert_file_match "$STATE_DIR/overrides.md" "^breach/notice-window: *24" \
    "the re-run changed the one key it was asked to change"
  assert_file_match "$STATE_DIR/overrides.md" "^custom/legacy-position: *hand-written" \
    "an unrecognized hand-written key survived the re-run"
  assert_file_match "$STATE_DIR/overrides.md" "^watchlist/regimes:.*Colorado" \
    "an untouched key from the first run survived the re-run"

  # Skipped questions write nothing at all — not an empty value, not the
  # playbook default echoed back as if it were chosen.
  for k in $SKIPPED_KEYS; do
    assert_file_absent_match "$STATE_DIR/overrides.md" "^$k:" \
      "skipped question wrote no $k key"
  done

  # Lead with the override, don't hedge between it and the default. Naming
  # the displaced 48h is CORRECT — the provenance rule asks for the rung and
  # what it beat — so this checks position, not absence. An earlier version
  # asserted 48h was absent and failed a transcript that was doing the right
  # thing.
  assert_head_match t7 15 "24 ?(h|hours)" \
    "the answer opens with the override, not a comparison of both values"
  assert_match t7 "24 ?(h|hours)" "a fresh session negotiates from the override, not the playbook default"
  assert_match t7 "(override|standard|house position|you set|practice-level)" \
    "names the rung it applied, per the provenance rule"

  criteria "t2 was ambiguous about jurisdictions — check that setup ASKED rather than inferring a narrower footprint."
  criteria "t3 confirmed against a shown delta: the proposed key/value lines appear in t2's reply before any write."
  criteria "The setup interview is one message of questions, not eight round-trips."
  criteria "t7 is a fresh session and still uses 24h — durability, not conversation memory."
  criteria "Skipping setup entirely still yields useful defaults (the persona scenario runs with no overrides file)."
}
