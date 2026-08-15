# Spec: privacy-counsel v1

## Problem Statement

A big-law privacy/AI/transactional partner gets consumer-grade output from
stock Claude: verbose, hedged, generic, explains basics, forgets positions
between sessions, mixes clients' contexts, and invents citations under
pressure. Existing legal AI (Legora-class) lives in separate platforms;
Anthropic's claude-for-legal plugins are practice-area silos requiring
per-area setup interviews and exposing dozens of commands.

## Solution

One public plugin for one persona — a senior privacy/AI/transactional
partner at a large firm (outside counsel, multi-client, US+EU default).
Install and start working: an always-on partner-mode profile (bottom line
first, 2–5 bullets, recommendation, stop), a house drafting voice, a
pre-filled privacy playbook with market positions, a matter system with
absolute client-confidentiality walls, and a curated skillset — 13 core
skills plus 7 imports chosen through the privacy-partner lens (AI
governance, tabular/diligence review, amendment history, reg watching).
All skills are hidden and trigger from plain language; the typed surface is
4 commands (setup, draft, brief, deep-dive). An optional short setup writes
durable overrides outside the plugin so updates never clobber them.

## User Stories

1. As a privacy partner, I want bottom-line-first answers capped at a few bullets, so that I read the answer, not a memo.
2. As a privacy partner, I want depth only when I ask ("explain", "dive deeper", "full analysis"), so that escalation is my call.
3. As a privacy partner, I want a DPA reviewed against real market positions with severity ranking and redlines, so that I start from a partner-grade markup.
4. As a privacy partner, I want the vendor's AI-training carve-out treated as the deal-breaker it is, so that the one position that changes my client's legal posture never hides in a list.
5. As a privacy partner, I want my positions durably overridable ("my standard breach notice is 48h"), so that the plugin negotiates from MY playbook, not a default.
6. As a privacy partner, I want an optional 5-minute setup capturing my workflow (client posture, jurisdictions, watchlist, deal mix), so that the plugin fits my practice without me editing files.
7. As a privacy partner, I want to skip setup entirely and still get useful defaults day one, so that there is zero configuration tax.
8. As a privacy partner, I want each client's matter strictly walled from every other, so that confidentiality survives the tooling.
9. As a privacy partner, I want work product saved per matter and rediscovered in later sessions, so that Tuesday's triage informs Thursday's DPA review.
10. As a privacy partner, I want honest pressure-testing of my positions (holds / doesn't hold / can't assess), so that I get a colleague, not a sycophant.
11. As a privacy partner, I want legal findings translated into deal consequences (indemnity, covenant, escrow, walk), so that analysis ends in an action.
12. As a privacy partner, I want company research through a privacy/deal lens (data flows, AI use, legal exposure), so that I skip founding stories and get to what matters.
13. As a privacy partner, I want drafts in a crisp partner register that I edit minimally, so that AI drafting saves time instead of creating rewrites.
14. As a privacy partner, I want briefings that select rather than summarize, with no material item ever silently dropped, so that I can walk into the room on 5 bullets.
15. As a privacy partner, I want vendor AI terms reviewed against my governance positions (training-on-data, model changes, liability), so that AI addenda get the same rigor as DPAs.
16. As a privacy partner, I want an EU AI Act inventory of my client's AI systems by role and risk tier, so that classification questions have a maintained answer.
17. As a privacy partner, I want AI impact assessments generated in a house format, so that AIA/DPIA work starts at 80%.
18. As a privacy partner, I want tabular review over a folder of contracts — one row per document, every cell quoting its source, no fabrication — so that 30-DPA diligence takes an afternoon.
19. As a privacy partner, I want diligence issues extracted from data-room documents by category and materiality, so that findings arrive structured.
20. As a privacy partner, I want a contract's amendment history traced clause-by-clause, so that "what changed since 2023" is answerable.
21. As a privacy partner, I want an on-demand sweep of my regulatory watchlist filtered by materiality, so that I hear about what moved, not everything.
22. As a privacy partner, I want every legal claim tagged with provenance ([model knowledge — verify], [web search — verify]) and no invented citations ever, so that I know what to check before relying.
23. As a privacy partner, I want currency-sensitive areas (AI regs, state privacy laws) checked against live sources, so that August's answer reflects July's omnibus.
24. As a privacy partner, I want the assistant to ask which matter I mean when context is ambiguous, so that nothing crosses a client wall by guess.
25. As a privacy partner, I want to ask "what can you do?" and "is my setup loaded?" and get straight answers, so that an invisible-by-design plugin is never a black box.
26. As a new user, I want install to be two commands from a public GitHub repo, so that adoption needs no authentication ceremony.
27. As a new user, I want the / picker to show 4 commands instead of 20 skills, so that the surface is learnable in one glance.
28. As the maintainer, I want every push to auto-update installs (no version pin), so that fixes reach users without a release process.
29. As the maintainer, I want vendored files to carry Apache-2.0 modification notices and a NOTICE file, so that redistribution is clean.
30. As the maintainer, I want a scripted headless test harness with written pass criteria, so that regressions are caught by scenario runs, not vibes.

## Implementation Decisions

- One plugin (`privacy-counsel`), one marketplace (`privacy-counsel-marketplace`), public repo `rbh227/privacy-counsel-plugin`. No version pin: commit SHA is the version.
- Persona is fixed: senior privacy/AI/transactional partner at a large firm, outside counsel, multi-client, US+EU default footprint. Not configurable in v1; privilege posture reads from the playbook.
- Always-on injection via SessionStart hook: profile + style guide inline, playbook by path reference. Profile self-identifies when asked whether the plugin/setup is active and can enumerate capabilities.
- All skills `user-invocable: false`. Typed surface: `/privacy-counsel:setup`, `:draft`, `:brief`, `:deep-dive`.
- Skillset = 13 core (challenge, company-understanding, deal-judgment, partner-briefing, partner-writing, tight-writing, matter-workspace, dpa-review, dsar-response, pia-generation, policy-monitor, reg-gap-analysis, use-case-triage) + 7 imports (vendor-ai-review, ai-inventory, aia-generation from ai-governance-legal; tabular-review, diligence-issue-extraction from corporate-legal; amendment-history from commercial-legal; reg-feed-watcher from regulatory-legal).
- Import adaptation contract: rewire upstream config references (`~/.claude/plugins/config/claude-for-legal/<area>/...`) to the plugin playbook + `~/.claude/privacy-counsel/` state; matter operations go through our matter system; output shape obeys partner mode and the work-product header rules; references to unshipped skills (launch-review, ai-tool-handoff, material-contract-schedule, legal-builder-hub, cold-start-interview, customize) are stripped or rerouted; references to ai-governance's use-case-triage / reg-gap-analysis / policy-monitor reroute to our privacy versions WITHOUT importing ai-gov's divergent cursor semantics (its human-acknowledgment gate is preserved wherever its own skills update state).
- reg-feed-watcher: on-demand only (no scheduled agents in v1); watchlist seeds from the playbook's regulatory footprint; user watchlist lives in overrides.
- Overrides: `~/.claude/privacy-counsel/overrides.md`, written by `/privacy-counsel:setup` (short interview: client posture mix, jurisdictions, deal mix, watchlist, output preferences) and by in-session "make that my standard" corrections. Precedence: in-session correction > overrides file > playbook default. Skills consult overrides wherever they consult the playbook.
- State layout (as validated by prior testing): `~/.claude/privacy-counsel/state.md` (registry + practice notes only, never an active-matter pointer), `matters/<slug>/{matter.md, history.md, notes.md, outputs/, sweep-state.md, verification-log.md}`, `law-notes.md`. Active matter is session-scoped. Cross-matter reads forbidden.
- Vendored once from anthropics/claude-for-legal @ 4a6c651 (already-held clone), never synced; verbatim import commit then overlay commits; upstream SHA and file list recorded in VENDORED.md.
- License: Apache-2.0 for the entire repo; NOTICE file added; §4(b) prominent modification notices on every adapted upstream file; upstream attribution retained.
- Old personalized plugin is retired at v1 on the development machine: uninstall, wipe test state, install privacy-counsel from the public repo (delivery rehearsal).
- Creating/pushing the public GitHub repo requires explicit user approval at execution time — never automatic.

## Testing Decisions

- One seam: the headless-session harness. Plugin behavior IS session behavior; tests run `claude -p` fresh sessions (hook fires as in production) fed scenario prompts, then grade transcripts against written pass criteria and assert on the filesystem state the session leaves behind. Multi-turn scenarios chain via `--resume`.
- Harness lives in `tests/` with per-scenario pass criteria in TESTING.md; scenarios cover: partner mode + persona, depth escalation, each core skill behavior, each of the 7 imports against OUR config (not upstream paths), override precedence (setup → new session honors override), matter isolation + ambiguity stop, artifact discovery across sessions, self-identification, non-legal control question.
- Good test = external behavior only: what the transcript says and what files exist afterward. Never grade by reading skill markdown.
- Prior art: the 14-scenario TESTING.md battery + scratchpad harness (lib.sh pattern: JSON output parsing, --resume chaining, scoped allowedTools) already used to validate the predecessor plugin.
- Known seam limits (manual checks, documented in TESTING.md): command-picker enumeration and headless write-permission to `~/.claude/privacy-counsel/` (headless sessions auto-deny; harness pre-creates state or asserts staged-degradation behavior).
- Static checks (scripts/static-checks.sh): hook syntax, JSON manifest validity, zero personal references, all skills carry `user-invocable: false`, no upstream config paths survive in adapted files.

## Out of Scope

- Workflow chains (/deal, /vendor, /reg) — v2 once real usage shows the sequences.
- Scheduled agents (reg-change-monitor, renewal-watcher, etc.).
- Non-privacy practice areas as wholes (commercial/corporate/product/regulatory beyond the 7 curated imports); litigation, employment, IP, law-student, legal-clinic entirely.
- Configurable personas (in-house GC mode); per-client playbook files beyond the overrides mechanism.
- MCP server manifests from upstream areas (Ironclad, iManage, etc.); v1 requests no MCP servers.
- Upstream sync tooling; documents-connector integrations; Excel/Sheets output paths of tabular-review beyond what the vendored skill degrades to gracefully.

## Further Notes

- Fidelity note: the house voice is intentionally opinionated (crisp declarative openings, "To be sure" concession-turns, graded uncertainty, no AI clichés) and is presented as a default register that yields to the user's samples/corrections — never attributed to any person.
- The plugin must never write into its own install directory; all mutable state lives in `~/.claude/privacy-counsel/`.
- Upstream tabular-review's anti-fabrication machinery (verbatim quotes, three not-found states, char-for-char spot checks) is a load-bearing feature — the overlay must not weaken it.
