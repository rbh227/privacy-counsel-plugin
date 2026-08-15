# Vendored code

Seven skill areas' worth of upstream work is redistributed here. Attribution
lives in `NOTICE`; the licence text lives in `LICENSE` (ours) and
`LICENSE-claude-for-legal` (upstream's copy, per Apache-2.0 §4(a)).

- **Repo:** https://github.com/anthropics/claude-for-legal
- **Commit:** `4a6c651889c97cc9140580363c73e0eb17379c2b`
- **Licence:** Apache-2.0

## What came from where

| Ours | Upstream path | State |
|---|---|---|
| `skills/use-case-triage` | `privacy-legal/skills/use-case-triage` | modified |
| `skills/pia-generation` | `privacy-legal/skills/pia-generation` | modified |
| `skills/dpa-review` | `privacy-legal/skills/dpa-review` | modified |
| `skills/dsar-response` | `privacy-legal/skills/dsar-response` | modified |
| `skills/reg-gap-analysis` | `privacy-legal/skills/reg-gap-analysis` | modified |
| `skills/policy-monitor` | `privacy-legal/skills/policy-monitor` | modified |
| `skills/matter-workspace` | `privacy-legal/skills/matter-workspace` | modified |
| `skills/vendor-ai-review` | `ai-governance-legal/skills/vendor-ai-review` | modified |
| `skills/ai-inventory` | `ai-governance-legal/skills/ai-inventory` | modified |
| `skills/aia-generation` | `ai-governance-legal/skills/aia-generation` | modified |
| `skills/tabular-review` | `corporate-legal/skills/tabular-review` | SKILL.md modified; `references/` verbatim |
| `skills/diligence-issue-extraction` | `corporate-legal/skills/diligence-issue-extraction` | modified |
| `skills/amendment-history` | `commercial-legal/skills/amendment-history` | modified |
| `skills/reg-feed-watcher` | `regulatory-legal/skills/reg-feed-watcher` | SKILL.md modified; `references/` verbatim |

Every file marked modified carries a §4(b) notice at its head saying what
changed. `scripts/static-checks.sh` check 9 enforces that: a vendored skill
without a notice, or a notice on a skill not listed here, fails the build.

## Recovering pristine upstream

There is **no local verbatim-import commit**, despite what an earlier
version of this file claimed. `docs/agents/toolchain.md` requires static
checks to pass on every commit, and an unmodified upstream file fails three
of them — it has no `user-invocable: false`, it points at
`~/.claude/plugins/config/claude-for-legal/...`, and it references skills
this plugin does not ship. A "verbatim" commit would have had to be modified
to exist, which defeats its own purpose.

Provenance comes from the SHA instead, which is stronger: the upstream file
is one command away, and it cannot drift.

```bash
git clone --filter=blob:none --no-checkout https://github.com/anthropics/claude-for-legal.git
git -C claude-for-legal archive 4a6c651889c97cc9140580363c73e0eb17379c2b \
    privacy-legal/skills/dpa-review | tar -x
```

Diff that against ours to see the whole adaptation.

## Overlay policy

Vendored once, deliberately never synced. Upstream is a moving target with
its own opinions about in-house practice; this plugin is outside counsel for
many clients, and the adaptation is not a patch that could be rebased.

Every import got the same treatment:

1. Configuration redirected from `~/.claude/plugins/config/claude-for-legal/<area>/CLAUDE.md` to `profile/privacy-playbook.md` and the practice overrides file.
2. Setup, cold-start, provisional and `[PLACEHOLDER]` gates removed — the playbook is always configured.
3. Upstream `/<area>-legal:*` command handoffs replaced with plain-language skill references; handoffs to skills this plugin does not ship removed rather than left dangling.
4. Mutable state moved under the state root named in the session-start status block.
5. The in-house "company" reread as the CLIENT of the active matter.
6. `user-invocable: false`, a §4(b) notice, and a `## practice overlay` section appended.

When changing a vendored skill, edit ours. Do not re-import.
