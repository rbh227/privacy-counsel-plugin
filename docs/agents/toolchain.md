# Toolchain

This repo is a Claude Code plugin: markdown skills + one bash hook + JSON
manifests. No build step, no package manager.

| Verb | Command | Notes |
|---|---|---|
| static | `scripts/static-checks.sh` | hook syntax, manifest JSON validity, zero personal references, hidden-skill frontmatter, no stale upstream config paths |
| test | `tests/run.sh <scenario-id>` | one headless-session scenario (created by ticket 02; until it exists, `static` is the only automated verb) |
| full suite | `tests/run.sh --all` | every scenario + static checks |

Rules:
- Run `static` before every commit.
- Scenario tests spawn real `claude -p` sessions — they cost tokens and
  minutes. Run the scenarios your ticket touches, not `--all`, during
  development; `--all` is for the final gate.
- Headless sessions cannot write to `~/.claude/privacy-counsel/` (permission
  auto-deny). The harness pre-creates state via its fixtures or asserts the
  staged-degradation path; see tests/README.md once ticket 02 lands.
