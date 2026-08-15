#!/usr/bin/env bash
# Probes for the static-checks grammar audit (7a pronouns, 7b sentence case).
#
# Each probe copies the repo's shipped tree into a throwaway directory, plants
# ONE case, and runs the REAL scripts/static-checks.sh there — so the evidence
# exercises the shipped checks verbatim rather than a re-typed approximation,
# and the working tree is never touched.
#
# Usage: scripts/static-checks-probe.sh [1..6]   (no arg = all six)
set -u
cd "$(dirname "$0")/.."
SRC="$PWD"
TREE="skills profile commands hooks references scripts .claude-plugin README.md TESTING.md VENDORED.md STATE.md"

sandbox() {
  local d
  d="$(mktemp -d)"
  # shellcheck disable=SC2086
  ( cd "$SRC" && cp -R $TREE "$d/" )
  echo "$d"
}

run() { ( cd "$1" && ./scripts/static-checks.sh 2>&1; echo "exit=$?" ); }

probe1() {
  echo "=== PROBE 1 — 7a MUST FIRE (gendered pronouns, incl. uppercase) ==="
  local d; d="$(sandbox)"
  cat > "$d/references/probe.md" <<'EOF'
He can ask to dive deeper.

The reviewer keeps his own copy.

Never ask him to file anything.

HIS rights under Article 15 are unaffected.
EOF
  echo "--- planted references/probe.md ---"; cat "$d/references/probe.md"
  echo "--- output ---"; run "$d"; rm -rf "$d"
}

probe2() {
  echo "=== PROBE 2 — 7a MUST NOT FIRE (both escape hatches + clean prose) ==="
  local d; d="$(sandbox)"
  # (a) vendored file exempted by path prefix in the allowlist
  mkdir -p "$d/skills/vendored-probe"
  cat > "$d/skills/vendored-probe/SKILL.md" <<'EOF'
user-invocable: false
The data subject may exercise his rights under Article 15; he or she must be
identified first.
EOF
  echo "skills/vendored-probe/" >> "$d/scripts/static-checks-allow.txt"
  # (b) file we author, exempted by inline marker
  cat > "$d/references/marker-probe.md" <<'EOF'
The data subject exercises his access right. <!-- static-checks: allow-pronoun -->
EOF
  # (c) correct de-personalized prose — must stay silent
  cat > "$d/references/clean-probe.md" <<'EOF'
The partner can ask to dive deeper. They see only what matters.
EOF
  echo "--- (a) allowlisted path: skills/vendored-probe/SKILL.md ---"
  cat "$d/skills/vendored-probe/SKILL.md"
  echo "--- (b) inline marker: references/marker-probe.md ---"
  cat "$d/references/marker-probe.md"
  echo "--- (c) clean prose: references/clean-probe.md ---"
  cat "$d/references/clean-probe.md"
  echo "--- output ---"; run "$d"; rm -rf "$d"
}

probe3() {
  echo "=== PROBE 3 — 7b MUST FIRE, once per Markdown prefix branch ==="
  local d; d="$(sandbox)"
  cat > "$d/references/probe.md" <<'EOF'
the partner opens a bare line.

Sentence one ends. the partner follows on the same line.

- the partner leads a dash bullet.

* the partner leads a star bullet.

3. the partner leads an ordered item.

> the partner leads a blockquote.

**the partner** leads with emphasis.

| Note | Done. the partner signs it. |

  - the partner leads an indented bullet.

## the partner leads a heading
EOF
  echo "--- planted references/probe.md ---"; cat "$d/references/probe.md"
  echo "--- output ---"; run "$d"; rm -rf "$d"
}

probe4() {
  echo "=== PROBE 4 — 7b MUST NOT FIRE (hard wrap, abbreviations, code, correct case) ==="
  local d; d="$(sandbox)"
  cat > "$d/references/probe.md" <<'EOF'
Escalation runs through counsel, and where the call is subjective
the partner decides, not Claude. That is the whole rule, and it wraps
across three lines because this corpus hard-wraps at roughly 72 columns and
the partner is its most common subject.

Depth is on request (e.g. the partner asks for a full analysis).

Scope is one footprint (i.e. the partner's US + EU default).

Notice follows Art. the partner will cite.

See No. the partner assigned.

Filed in the U.S. the partner confirms.

Escalation is required. The partner decides, never Claude.

| Reviewer | the partner |

A table cell is a fragment, not a sentence — the row above is correct prose.

Use `config.md. the partner` when naming the file.

See [the docs](http://example.com/a.b) the partner keeps.

```
the partner inside a fenced code block is not prose.
```
EOF
  echo "--- planted references/probe.md ---"; cat "$d/references/probe.md"
  echo "--- output ---"; run "$d"; rm -rf "$d"
}

probe5() {
  echo "=== PROBE 5 — a content-scoped exemption must NOT blind the rest of the file ==="
  local d; d="$(sandbox)"
  cat > "$d/references/probe.md" <<'EOF'
The data subject exercises his rights under Article 15.

He can ask to dive deeper.
EOF
  echo "references/probe.md::data subject exercises his" >> "$d/scripts/static-checks-allow.txt"
  echo "--- planted references/probe.md ---"; cat "$d/references/probe.md"
  echo "--- allowlist entry: references/probe.md::data subject exercises his ---"
  echo "--- expected: line 1 exempted, line 3 STILL REPORTED ---"
  echo "--- output ---"; run "$d"; rm -rf "$d"
}

probe6() {
  echo "=== PROBE 6 — an allowlist entry that exempts nothing MUST FAIL ==="
  local d; d="$(sandbox)"
  echo "skills/never-existed/" >> "$d/scripts/static-checks-allow.txt"
  echo "--- allowlist entry: skills/never-existed/ (matches no file) ---"
  echo "--- output ---"; run "$d"; rm -rf "$d"
}

case "${1:-all}" in
  1) probe1 ;;
  2) probe2 ;;
  3) probe3 ;;
  4) probe4 ;;
  5) probe5 ;;
  6) probe6 ;;
  *) probe1; echo; probe2; echo; probe3; echo; probe4; echo; probe5; echo; probe6 ;;
esac
