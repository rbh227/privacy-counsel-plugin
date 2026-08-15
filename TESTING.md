# Testing privacy-counsel

Two tiers. The scenario battery is automated and lives in `tests/` — see
`tests/README.md` for how it works and what it cannot tell you. The manual
checks below need a human in the Cowork UI and have no automated substitute.

Install for local testing, without GitHub:

```
/plugin marketplace add /Users/raphaelhaytene/code/privacy-counsel-plugin
/plugin install privacy-counsel@privacy-counsel-marketplace
```

then start a new session.

## Automated battery

```bash
tests/run.sh --all          # the gate: every scenario must run and pass
tests/run.sh <id>           # one scenario
```

Every run starts with a preflight session proving the sessions load the tree
you are testing, and redirects the plugin's state root to a throwaway
directory so no real matter is touched. Pass criteria that need judgment are
printed after each scenario for a human to grade against the saved
transcript — a green exit code does not discharge them.

Every scenario is active as of ticket 08 — nothing is pending on unbuilt
work. A skipped scenario still fails `--all` unless you pass `--partial`,
which is what makes this command a gate rather than a report.

| # | Scenario | State | Proves |
|---|---|---|---|
| 01 | `persona` | active | Fixed large-firm partner persona; self-identification answers from the component status block |
| 02 | `partner-mode` | active | Bottom line first, 2–5 bullets, then real escalation on "give me the full analysis" |
| 03 | `dpa-review` | active | Work-product header, severity ranking, minor-points line, no setup prompt; blocked save disclosed rather than silently dropped |
| 04 | `challenge` | active | One of the three honest verdicts, verdict first, no sycophancy |
| 05 | `client-note` | active | The draft arrives first, in the client register; deliverable exemption from brevity holds |
| 06 | `briefing` | active | `/privacy-counsel:brief` shape; nothing material silently dropped |
| 07 | `dpia-triage` | active | DPIA classification with reasoning and stated assumptions |
| 08 | `non-legal-control` | active | A non-legal question does not misfire a legal skill |
| 09 | `matter-ambiguity` | active | Two live matters: stops and asks before touching matter files |
| 10 | `artifact-discovery` | active | Work product saved per matter and rediscovered by a fresh session; sweep cursor per matter; active matter never persisted |
| 11 | `setup-overrides` | active (state) | Setup writes durable overrides in the keyed format; a re-run changes one key and preserves the rest; a fresh session applies one and names the rung |
| 12 | `vendor-ai-review` | active | Vendor AI terms reviewed against `## Vendor AI governance`; training-on-data and flow-down flagged |
| 13 | `ai-inventory` | active (state) | EU AI Act role and risk tier per system, with the basis recorded and tagged for verification |
| 14 | `aia-generation` | active (state) | AI impact assessment in the house format, classified per regime in scope |
| 15 | `tabular-review` | active | One row per document, every cell quoted to source; the three not-found states preserved |
| 16 | `diligence-extraction` | active (state) | Diligence issues by category and materiality, with a pre-closing action list |
| 17 | `amendment-history` | active | Amendment history traced clause by clause |
| 18 | `reg-feed-watcher` | active (web, state) | On-demand sweep filtered by materiality; a first sweep reports as a first sweep |
| 19 | `capability-map` | active | "What can you do?" answered without exposing the skill list |
| 20 | `company-understanding` | active (web) | Company research through the privacy/deal lens, sourced |
| 21 | `deep-dive` | active (web) | `/privacy-counsel:deep-dive` depth with honest citation tags, no invented citations |
| 22 | `standing-correction` | active (state) | An ordinary correction stays in-session; "make that my standard" proposes, waits, then persists on confirmation |

## Manual checks

None of these can run headlessly. Run them in Cowork before delivery.

**M1 — Command picker.** Type `/` and read the list. Only the
`/privacy-counsel:*` commands appear from this plugin; none of the skills
are listed as user-invocable entries.

**M2 — First-write permission prompt.** On the first write to the state
root, Cowork asks for permission once. Approve it. Confirm the write lands
and the session says what it saved. (Headless sessions auto-deny this — the
reason scenario 03 tests the degradation path instead.)

**M3 — Plugin disable.** `/plugin disable privacy-counsel`, restart, ask a
legal question. Stock behavior returns, nothing is broken, no orphaned
context, no dangling references to matters or the playbook.

**M4 — Concurrent sessions.** Open two sessions, A on one matter and B on
another. Ask a follow-up in each. Each stays in its own matter; neither
reads or writes the other's files. The active matter is session-scoped and
never appears in `state.md`.

**M5 — Component status honesty.** Ask "is my setup loaded?" in a session
where no `overrides.md` exists. The answer confirms the profile and says
separately that no durable overrides were found — not a flat "yes, you're
set up". Then rename `profile/privacy-playbook.md`, restart, and ask again:
the session reports the playbook missing instead of silently proceeding.

**M6 — State layout.** After any matter work, the state root holds
`state.md` (registry and practice notes, no active-matter pointer) and
`matters/<slug>/outputs/`. Nothing was written into the plugin directory.
