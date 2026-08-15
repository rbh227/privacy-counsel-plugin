#!/usr/bin/env bash
# SessionStart hook: inject the working profile + style guide, name the state
# root, and report which components actually loaded.
#
# Two rules, in tension, both mandatory:
#   1. Never break a session — every path exits 0, whatever is missing.
#   2. Never let a silent skip become a false "yes, your setup is loaded".
# Rule 1 alone produced exactly that bug: a missing playbook was skipped in
# silence while the profile told the session to confirm setup unconditionally.
# So a missing component is now reported, not hidden.
set -u

DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE_ROOT="${PRIVACY_COUNSEL_HOME:-$HOME/.claude/privacy-counsel}"

PROFILE="$DIR/profile/counsel-profile.md"
STYLE="$DIR/profile/style-guide.md"
PLAYBOOK="$DIR/profile/privacy-playbook.md"
OVERRIDES="$STATE_ROOT/overrides.md"

# status_of <path> [missing-word] — loaded | missing | unreadable | empty
status_of() {
  if [ ! -e "$1" ]; then echo "${2:-missing}"
  elif [ ! -r "$1" ]; then echo unreadable
  elif [ ! -s "$1" ]; then echo empty
  else echo loaded
  fi
}

profile_st="$(status_of "$PROFILE")"
style_st="$(status_of "$STYLE")"
playbook_st="$(status_of "$PLAYBOOK")"
overrides_st="$(status_of "$OVERRIDES" absent)"

[ "$profile_st" = loaded ] && cat "$PROFILE" && echo
[ "$style_st" = loaded ] && cat "$STYLE" && echo

cat <<EOF
# privacy-counsel — session component status

Answer any "is my setup / profile / plugin loaded?" question from this
block, never from assumption. Report the profile and the durable overrides
separately: they are different things and they fail independently.

| Component | Status |
|---|---|
| Working profile | $profile_st |
| House style guide | $style_st |
| Practice playbook | $playbook_st |
| Practice overrides | $overrides_st |

Practice playbook: $PLAYBOOK
  Read it before substantive privacy/AI/deal work — its guardrails apply
  even when no skill runs.

Practice overrides: $OVERRIDES
  "absent" is normal, not an error: no durable overrides were saved, so
  playbook defaults apply. Say so plainly if asked. Never report durable
  positions as loaded when this line says absent, and never prompt for
  setup on account of it.

Mutable state root: $STATE_ROOT
  Every matter file, log, and sweep cursor lives under this path. Never
  write into the plugin directory, and use this path rather than a
  hardcoded home directory — a test or sandbox session points it elsewhere
  via PRIVACY_COUNSEL_HOME.
EOF
exit 0
