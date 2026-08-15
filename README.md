# privacy-counsel

A Claude plugin for a senior privacy, AI, and transactional lawyer —
outside counsel, multiple clients, US and EU by default.

It changes how Claude answers you: bottom line first, a few bullets of what
actually matters, a recommendation, then it stops. No restating your
question, no explaining what a DPIA is. Say **"explain"**, **"dive
deeper"**, or **"give me the full analysis"** when you want more.

## Install in Cowork

Type these two commands in Claude Cowork (or Claude Code):

```
/plugin marketplace add rbh227/privacy-counsel-plugin
```

```
/plugin install privacy-counsel@privacy-counsel-marketplace
```

Then start a new session. That's it.

The first time it saves a document it will ask permission to write to
`~/.claude/privacy-counsel/` — approve it once. Your work and your saved
positions live there, outside the plugin, so updating never touches them.

**Optional:** run `/privacy-counsel:setup` once. Eight questions, all
skippable, about your footprint, posture, deal mix and preferred positions.
Skip it entirely and everything still works — it just uses sensible defaults
instead of yours.

## The skills

Twenty of them. You never name one — just ask in plain language and the
right one engages.

### Deals and diligence

| Skill | What it does |
|---|---|
| **company-understanding** | Researches what a company actually does — offerings, customers, data flows, AI use — through a privacy and deal lens |
| **deal-judgment** | Turns a legal finding into a transaction consequence: price, indemnity, walk away, or noise |
| **diligence-issue-extraction** | Reads a data room and extracts issues by category and materiality, in memo format |
| **tabular-review** | Reviews a folder of contracts into a table — one row per document, every cell quoted to its source |
| **amendment-history** | Traces how a contract changed across its base agreement and every amendment |
| **partner-briefing** | Compresses a pile of material into what matters, what needs deciding, and what to do next |

### Privacy

| Skill | What it does |
|---|---|
| **dpa-review** | Reviews a Data Processing Agreement against your playbook, working out whether you're controller or processor |
| **use-case-triage** | Decides whether an activity needs a PIA, a mandatory DPIA, or can proceed |
| **pia-generation** | Writes the privacy impact assessment itself, in house format |
| **dsar-response** | Walks a data subject request through identity, location, exemptions, and drafts the response letters |
| **reg-gap-analysis** | Diffs a new or changed regulation against current policy and practice, with owners and dates |
| **policy-monitor** | Finds where the published privacy policy no longer matches what the team actually does |
| **reg-feed-watcher** | Sweeps regulatory sources on demand and reports what moved, filtered by materiality |

### AI

| Skill | What it does |
|---|---|
| **vendor-ai-review** | Reviews vendor AI terms — training on your data, liability, model changes, and what flows down the vendor stack |
| **ai-inventory** | Classifies AI systems by EU AI Act role and risk tier, per system, recording the basis |
| **aia-generation** | Runs an AI impact assessment: intake, risk analysis, classification per regime in scope |

### Writing and thinking

| Skill | What it does |
|---|---|
| **partner-writing** | Drafts in your voice — the draft first, not an essay about the draft |
| **challenge** | Pressure-tests a position you've taken: it holds, it doesn't, or here's the fact that decides it |
| **tight-writing** | Cuts existing text down to what earns its place |
| **matter-workspace** | Keeps each client's matter walled off from every other |

## The four commands

Shortcuts only — plain language does the same work.

| Command | For |
|---|---|
| `/privacy-counsel:setup` | Record your practice defaults (optional, once) |
| `/privacy-counsel:draft` | Force the drafting voice |
| `/privacy-counsel:brief` | Force the briefing shape |
| `/privacy-counsel:deep-dive` | Full analysis, brevity off |

## Client confidentiality

Matters are separated. The active matter is worked out per session and never
written to disk, so two sessions on two clients can't bleed into each other.
Nothing reads across matters. When two matters could both fit what you said,
it stops and asks instead of guessing.

## Update and uninstall

```
/plugin update privacy-counsel@privacy-counsel-marketplace
```

```
/plugin uninstall privacy-counsel@privacy-counsel-marketplace
```

Uninstalling leaves `~/.claude/privacy-counsel/` alone — your matters and
saved positions survive. Delete that folder yourself if you want them gone.

## Licence

Apache-2.0. Seven of the twenty skills are adapted from
[anthropics/claude-for-legal](https://github.com/anthropics/claude-for-legal),
also Apache-2.0 — see `NOTICE` and `VENDORED.md` for what came from where
and what changed.
