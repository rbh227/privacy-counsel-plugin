---
description: Capture your practice defaults once — footprint, posture, deal mix, watchlist, output preferences
argument-hint: ""
disable-model-invocation: true
---

Capture the partner's durable practice defaults and write them to the
practice overrides file. Everything here is optional: the playbook works on
day one without it, and this command exists to make the plugin fit a
practice, not to extract configuration.

## Where the file goes

The **state root** named in the session-start component status block —
`~/.claude/privacy-counsel/` unless `PRIVACY_COUNSEL_HOME` points elsewhere.
The file is `overrides.md` at that root. Never write it inside the plugin
directory: a plugin update would clobber it.

Create the state root if it does not exist. The first write there may raise
a one-time permission prompt — that is expected; ask for it plainly rather
than routing around it. If the write is denied or fails, do not retry
silently and do not pretend it worked: print the exact file content in a
fenced block, say where to save it, and stop.

## The interview

Ask all of it in ONE message as a numbered list, not eight round-trips. A
senior partner answers what matters to them and ignores the rest; a wizard
that walks them through eight turns is the tax this plugin exists to avoid.

Open with one line: what this does, that every question is optional, and
that they can answer a subset, say "defaults", or abandon it entirely.

1. **Footprint** — which privacy regimes are actually in scope? (default: US
   + EU)
2. **Posture** — is the client usually the controller/customer, the
   processor/vendor, or genuinely mixed? (default: mixed, inferred per
   matter)
3. **Deal mix** — what lands most: M&A diligence, vendor DPAs, product
   counseling, regulatory response?
4. **Breach notice** — the notice window you ask vendors for. (playbook
   default: ≤48h from awareness, controller side)
5. **Liability** — your standard ask on data-claim liability. (playbook
   default: data-breach super-cap or 2–3× fees)
6. **Transfers** — preferred mechanism where both are available. (playbook
   default: SCCs/IDTA, DPF where certified)
7. **Watchlist** — regimes or regulators to track beyond the footprint (EU
   AI Act, Colorado AI Act, state comprehensive laws, sectoral rules).
8. **Outputs** — save work product to the matter by default, or only when
   asked? Any change to the work-product header?

Skipped questions write NOTHING. An unanswered question must not produce an
empty key, a "not specified" value, or a key echoing the default — all three
turn a skipped question into a durable position, and the playbook default
then looks like a deliberate choice nobody made.

## Writing the file

Use the format defined in `../profile/privacy-playbook.md` `## Overrides`:
one position per line, `key: value`, under an `## Overrides` heading. Keys
name the position, not the prose around it. Use these keys, and only add a
new one when no existing key fits:

| Question | Key | Example value |
|---|---|---|
| 1 | `footprint/regimes` | `GDPR, CPRA, Colorado CPA` |
| 2 | `posture/default` | `controller-side` |
| 3 | `deals/primary` | `vendor DPAs, then M&A diligence` |
| 4 | `breach/notice-window` | `48h from awareness` |
| 5 | `dpa/liability-cap` | `2x fees, data super-cap` |
| 6 | `transfers/mechanism` | `SCCs; DPF only where certified` |
| 7 | `watchlist/regimes` | `EU AI Act, Colorado AI Act` |
| 8 | `outputs/save-by-default` | `yes` |
| 8 | `outputs/header` | `PRIVILEGED & CONFIDENTIAL — ATTORNEY WORK PRODUCT` |

**Each key replaces its playbook default outright, except two that extend
it:** `watchlist/regimes` adds to the footprint rather than narrowing it,
and `deals/primary` ranks emphasis without excluding anything. Say which
behavior applies when the answer could be read either way.

### Show the delta before writing

The partner answers in prose; the file stores typed positions. That
translation is yours, it is frequently ambiguous, and its output governs
every future matter — so it gets one confirmation.

Before writing anything, show the exact lines you propose, old value beside
new where a key already exists, and ask for a single yes. Nothing goes to
disk before that yes.

```
footprint/regimes: GDPR, CPRA          (currently: practice default US + EU)
breach/notice-window: 48h from awareness   (currently: 48h from awareness — unchanged)
```

Where an answer does not resolve to a value, ask rather than infer — one
short question, not a re-run of the interview. "Mostly EU clients" is not a
regime list: it could mean GDPR only, or GDPR plus the US default retained.
Guessing narrows a partner's jurisdictional scope across every future
matter, and the narrowing is invisible afterward because the file reads
like a deliberate choice.

If the partner declines to confirm, write nothing and say so.

Write the file with a header comment naming what wrote it and when, then the
`## Overrides` heading, then the answered keys in the order above.

**Re-running setup is an edit, not a reset.** If `overrides.md` already
exists: read it first, show the current value beside each question, change
only the keys they answer this time, and leave every other line untouched —
including keys you do not recognize, which may have been hand-written or
added by a later version. Never rewrite the file from scratch.

## Closing

Confirm in two lines at most: which keys were written, and where. Then say
that in-session corrections still beat this file, and that
`/privacy-counsel:setup` can be re-run any time to change one answer.

Do not summarize the interview back to them, do not restate the values in
prose after the confirmation line, and do not offer next steps.
