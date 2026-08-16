---
user-invocable: false
name: dpa-review
description: >
  Review a Data Processing Agreement against your DPA playbook — auto-detects
  whether you're processor or controller and applies the right half of the playbook.
  Use when the user says "review this DPA", "check this data processing addendum",
  "customer sent their DPA", "is this DPA okay", or attaches a DPA.
argument-hint: "[file | Drive link | paste text]"
---
<!-- MODIFIED from anthropics/claude-for-legal (Apache-2.0), commit 4a6c651 — see VENDORED.md.
Changes: configuration redirected to this plugin's pre-filled practice playbook (../../profile/privacy-playbook.md),
setup/cold-start gates removed (playbook is always configured), /privacy-legal:* command handoffs replaced
with natural-language skill references, mutable state moved to ~/.claude/privacy-counsel/, practice overlay appended. -->

# /dpa-review

1. Load `../../profile/privacy-playbook.md` → DPA playbook (pre-configured; matter-specific client playbooks override its defaults).
2. Get the DPA. Determine direction: are we processor (customer's DPA) or controller (vendor's)? Ask if ambiguous.
3. Run the workflow below — term-by-term against the appropriate playbook row.
4. Run privacy policy consistency check.
5. Output: review memo with redlines. Save per house style.

Triggered from plain language — "take a look at this DPA", "is this DPA
okay" — with the document pasted or attached.

---

# DPA Review

## Matter context

**Matter context.** Matter workspaces are enabled and silent (see the playbook's `## Matter workspaces`; the active matter is SESSION-scoped — resolved from this session's own context against the registry in `~/.claude/privacy-counsel/state.md`; any legacy `Active matter:` line found in state.md is stale — ignore it). Infer the active matter by exact, unique client/matter match; when two matters could both fit, STOP and confirm before touching matter files. Load the active matter's `matter.md` for matter-specific context and overrides. Write deliverables to `~/.claude/privacy-counsel/matters/<matter-slug>/outputs/` (matter-slug `general` when no matter applies). Never read another matter's files — cross-matter context is off; client confidentiality between matters is absolute.

---

## Purpose

DPAs come in two flavors and the review is nearly opposite for each. When a customer sends their DPA, we're defending our operational flexibility. When we send one to a vendor, we're protecting our (and our customers') data. Both reviews read from the same `../../profile/privacy-playbook.md` playbook but from opposite rows.

## First: which direction?

Before anything else, establish:

- **We are the processor** → customer is sending us their DPA → read `../../profile/privacy-playbook.md` → "When we are the processor" table
- **We are the controller** → we're sending a DPA to a vendor (or reviewing theirs) → read "When we are the controller" table

If unclear, ask. Getting this wrong inverts every recommendation.

## Jurisdiction assumption

This review assumes the jurisdictional scope specified in your configuration. Privacy rules, response deadlines, and lawful bases vary materially by jurisdiction (GDPR vs. state consumer privacy laws vs. sectoral). If the controller, processor, or data subjects are in a different jurisdiction than configured, this review may not apply as written.

## Load prior context on this counterparty / activity

Before reviewing, check the outputs folder for prior work on this counterparty or processing activity. Read `../../profile/privacy-playbook.md` → `## Outputs` for the outputs folder path. Scan for:

- **Prior `use-case-triage` results** for the same counterparty / processing activity — the triage produces a risk rating and conditions that this DPA review should honor or explicitly depart from.
- **Prior `pia-generation` outputs** covering this counterparty / processing activity — the PIA may have flagged risk mitigations the DPA needs to implement.
- **Prior `dpa-review` outputs** for the same counterparty — earlier DPA reviews set expectations about what was acceptable, what was flagged, and what was settled. A fresh review that silently contradicts the earlier one erodes trust in the work product.

If a prior output is found, cite it in the review:

> "Prior triage ([date]) rated this [risk level] and conditioned approval on [X]. This DPA review is consistent with that finding." — or —
> "Prior triage ([date]) rated this [risk level]. This DPA review departs from that finding because [reason — new facts, different scope, contract term that changed the picture]."

**Carry severity from the upstream output as a floor** per the cross-skill severity floor rule in `../../profile/privacy-playbook.md` → `## Shared guardrails`. A processing activity the triage rated 🔴 cannot be quietly downgraded to 🟢 in the DPA review; any demotion is stated and explained.

If no prior output is found (new counterparty / new activity), say so explicitly in the review — "No prior triage or PIA on this counterparty in outputs folder" — so the reviewing attorney knows the check ran.

## Load the playbook

Read `../../profile/privacy-playbook.md` → `## DPA playbook`. Also read `## Privacy policy commitments` — the DPA can't contradict what the privacy policy promises.

## Federal sectoral overlay (ask first, before the term-by-term walk)

Before walking the term-by-term review, answer: **does the data flowing through this DPA include any federally-regulated category?** GDPR and state consumer-privacy law supply one floor; federal sectoral law often supplies another that does not appear in the generic DPA playbook. A DPA that is GDPR-complete can still be GLBA-blind, HIPAA-blind, or COPPA-blind, and a fintech / healthtech / edtech / kidtech counterparty will notice.

> **Activity-based federal overlays — ask first:**
>
> Does this processing touch:
> - **Financial account data or "nonpublic personal information" about consumers** (GLBA / Reg P)? If yes, the DPA needs: (a) an NPI-sharing restriction consistent with 15 U.S.C. § 6802(a)-(c) and Reg P (no sharing for marketing to non-affiliated third parties without opt-out / opt-in), (b) safeguards language aligned with the Safeguards Rule (16 C.F.R. Part 314), (c) incident notification that reaches FTC/OCC timing where applicable, (d) a clean carve-out so a CCPA § 1798.145(e) exemption doesn't accidentally waive GLBA-level obligations.
> - **Protected health information held by a covered entity or business associate** (HIPAA Privacy / Security Rules)? If yes, the DPA needs: a Business Associate Agreement (BAA) layered with or integrated into the DPA per 45 C.F.R. § 164.504(e), breach notification timing aligned with HITECH (60 days to CE; CE 60 days to HHS; 500+ threshold for media), permitted-uses clause, subcontractor BAA flow-down. A commercial DPA without BAA flow-down for PHI is a defect.
> - **Education records held by a school or a service provider acting for a school** (FERPA)? If yes, the DPA needs: a "school official" / directory-information framing consistent with 34 C.F.R. § 99.31, parental-consent flow-through, state student-privacy analog handling (NY Ed Law 2-d, CA SOPIPA, IL SOPPA).
> - **Data from children under 13 collected by an operator of an online service directed to children or with actual knowledge** (COPPA)? If yes, the DPA needs: verifiable-parental-consent flow-through, retention limits, deletion-on-request machinery, prohibition on behavioral advertising absent VPC.
> - **Another sectoral federal regime** (VPPA for video-viewing records, CPNI for carrier data, DPPA for DMV records, TCPA / Shaken-Stir for call/SMS, GLBA Reg S-P for broker-dealers, §5 FTC Act for unfair/deceptive practices around sensitive data)?
>
> If yes to any: the federal overlay usually supplies the controlling substantive restriction, not just an exemption from a state consumer privacy law. Research the currently-operative provision and cite it. A DPA that is "exempt" from CCPA under § 1798.145(e) because it is GLBA-covered is still subject to the GLBA restrictions — the CCPA exemption moves the governing framework, it doesn't eliminate it. Flag sectoral gaps in the deal-breakers list alongside GDPR / state-privacy gaps.

If no sectoral overlay applies, note that explicitly — "no federally-regulated data categories identified; sectoral overlay n/a" — so the reviewing attorney sees that the check happened, rather than wondering whether it was skipped.

## The term-by-term review

### Core terms (check every DPA)

Walk every DPA through these terms, clause by clause. The *specific* numeric and substantive positions (notice periods, breach timelines, acceptable/unacceptable floors) come from `../../profile/privacy-playbook.md` → `## DPA playbook`. The regulatory floors that any DPA has to clear come from primary law — **research the currently operative rule** for each applicable regime and cite primary sources before stating a floor.

> **No silent supplement.** If a research query to the configured legal research tool returns few or no results for a regime's breach window, transfer-mechanism requirement, subprocessor-change rule, or any other floor, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / topic]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against a primary source before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution tiering.** Tag every citation in the review — regulatory floors, SCC versions, adequacy decisions, regulator guidance, case law — with its source. For model-knowledge citations, use one of three tiers rather than a single blanket "verify" tag:
>
> - `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., GDPR Art. 28, Art. 33 72-hour breach notice, SCC Decision 2021/914 by number). Still verify before filing, but lower priority.
> - `[verify]` — model-knowledge citations that are real but should be verified: specific implementing regulations, regulator guidance, case holdings, adequacy decisions, SCC modules and versions, UK Addendum / IDTA status, thresholds, effective dates.
> - `[verify-pinpoint]` — pinpoint citations (specific subsection letters, clause numbers within SCCs, paragraph numbers, volume/page references) carry the highest fabrication risk and should ALWAYS be verified against a primary source.
>
> Tool-retrieved citations keep their source tag (`[Westlaw]`, `[Commission / regulator site]`, or the MCP tool name); web-search citations remain `[web search — verify]`; user-supplied citations remain `[user provided]`. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.

| Term | Looking for | Playbook field | Common fights |
|---|---|---|---|
| **Roles** | Clear controller/processor designation; matches reality | — | Counterparty labels the relationship (e.g., "joint controller") in a way that doesn't match reality |
| **Processing scope** | Limited to documented instructions; defined purposes | — | Open-ended scope expanders ("and related purposes") |
| **Subprocessors** | Current list disclosed, change mechanism defined | Subprocessor changes | Blanket approval vs. veto vs. notice-only |
| **Security measures** | Annex references specific controls or standards | Security standards | "appropriate technical and organizational measures" with no annex = empty promise |
| **Breach notification** | Defined trigger ("discovery" vs "confirmation"), defined timeline | Breach notification | Timeline tightness; clock trigger; "without undue delay" is vague |
| **Audit rights** | Method (report vs. on-site), frequency, notice, cost allocation | Audit rights | On-site audits on tight notice |
| **International transfers** | Transfer mechanism identified, supplementary measures, transfer impact assessment reference | Transfers | Outdated or missing transfer mechanisms |
| **Deletion/return** | Timeline post-termination, certification, backup carveout | Deletion on termination | "Commercially reasonable" deletion = ??? |
| **Liability** | Within MSA cap or separate; carveouts | Liability for data | Uncapped data breach liability = existential |

### When we're the processor: defensive review

Customer DPAs try to push operational burden onto us. For each clause below, compare the customer's ask to the playbook. Where the customer's ask is outside the playbook, push back to the team's standard position (from `../../profile/privacy-playbook.md` → DPA playbook, or the matter's client playbook) and be ready to fall back to the acceptable position.

| Clause | Risk | Research / playbook lookup |
|---|---|---|
| Subprocessor approval right (veto) | Can't add infrastructure without customer-by-customer approval | Apply playbook position on subprocessor changes |
| On-site audit on short notice | Unworkable at scale | Apply playbook position on audit rights |
| Aggressive breach notification window | Often demands notice before we know what happened | Research the regulatory floor for each applicable regime (cite primary sources); compare to playbook position |
| Hard data residency (single country/DC) | May not match architecture | Apply playbook position on data location; confirm what we can actually commit to |
| Processor liability uncapped | Bet-the-company | Apply playbook position on liability for data |
| Customer may issue binding "instructions" | Open-ended operational control | Define instructions as "documented in the Agreement or agreed in writing" |
| Deletion on very short timeline | Backup and log retention makes this impossible | Apply playbook position on deletion on termination; document backup rotation carveout |

### When we're the controller: protective review

Vendor DPAs try to give us nothing. For each clause below, compare to the controller-side playbook.

| Clause | Gap | Research / playbook lookup |
|---|---|---|
| No subprocessor list | Don't know who touches our data | Require published current list + advance notice per playbook |
| "Industry standard security" | Means nothing | Require annex with specific controls, or reference to a named standard (e.g., SOC 2, ISO 27001) |
| No breach notification timeline | They tell us whenever | Research applicable regulatory floor; require playbook position |
| No audit rights at all | Can't verify anything | Require at minimum an independent audit report per playbook |
| Vendor can use data for "service improvement" | Potential training on our data | Strike; processing limited to providing the service to us |
| No international transfer mechanism | No lawful transfer mechanism | **Research the currently operative transfer mechanism** for the corridor in question (origin/destination jurisdictions, applicable regime, any adequacy decision, any supplementary measures). Cite primary sources and verify currency. |
| No deletion commitment | Data lives forever | Require playbook position on deletion + certification on request |

## Consistency check: privacy policy

The DPA you sign can't promise something the privacy policy doesn't cover, and vice versa.

- If the DPA commits to processing only for purposes X, Y, Z — does the privacy policy list those purposes?
- If the privacy policy says "we never sell data" — does any DPA clause look like a sale under CCPA?
- If the privacy policy names specific subprocessor categories — does the DPA subprocessor list match?

Flag mismatches. They're usually the privacy policy being stale, not the DPA being wrong, but someone needs to fix one of them.

## Redline granularity

**Edit at the smallest possible granularity.** A redline is a negotiation artifact, not a rewrite. Wholesale clause replacement signals "we threw out your drafting" — it's aggressive, it forces the counterparty to re-read the whole clause, and it discards the parts of their drafting that were fine. Surgical redlines — strike a word, insert a phrase, restructure a subclause — signal "we have specific asks" and are faster to read, understand, and accept.

Default to the smallest edit that achieves the playbook position:
- Replace a **word** before a phrase. ("twelve (12)" → "twenty-four (24)")
- Replace a **phrase** before a sentence. ("paid by the Buyer" → "paid and payable by the Buyer")
- Restructure a **subclause** before replacing the sentence. (Add "(a)" and "(b)" to split a compound condition.)
- Replace a **sentence** before replacing the clause.
- Only replace a **whole clause** when the counterparty's version is so far from your position that surgical edits would be harder to read than a fresh draft — and when you do, say so in the transmittal: "We've replaced §8.2 rather than marking it up because the changes were extensive. Happy to walk you through the delta."

When in doubt, smaller. A client who receives a surgical redline trusts that you read carefully. A client who receives a wholesale replacement wonders whether you read at all.

## Output

Prepend the work-product header from `../../profile/privacy-playbook.md` `## Outputs` (it differs by user role — see `## Who's using this`).

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs]

# DPA Review: [Counterparty]

**Direction:** [We are processor / We are controller]
**Reviewed:** [date]
**Attached to:** [MSA / standalone]

---

## Bottom line

[Two sentences. Can we sign? What has to change?]

**Issues:** [N]🟢 [N]🟡 [N]🟠 [N]🔴

---

## Term-by-term

[Only the terms that matter. Walk every core term in the review above — then
put in this section only the ones worth the partner's attention, using a
standard deviation-memo format: what the counterparty's DPA says, what our
playbook says, the gap, the risk, and the proposed redline language. Keep
each to a short self-contained block so a reviewer can skim.

Close the section with one line — "N minor points available on request" —
covering everything you reviewed and left out. Do not table them, list them,
or summarize them by section number: offering them and enumerating them
anyway is the same as dumping. Materiality invariant: anything legally
material always survives the cut, however dull.]

---

## Privacy policy consistency

[🟢 Consistent | 🟡 Flags: list]

---

## Recommended redlines

[Consolidated — ready to send back]

---

## If they won't move

[For each issue: the fallback from the playbook (or the matter's client playbook), or escalation routing if no
fallback exists]
```

## International transfers note

If the DPA contemplates cross-border data transfers, **research the currently operative transfer mechanism requirements** for the applicable corridor(s). For each origin/destination pair, identify: the applicable regime, whether any adequacy decision is in force, which transfer mechanism is required or available (e.g., Standard Contractual Clauses and their applicable version/module, UK Addendum or IDTA, BCRs, derogations), whether a transfer impact assessment or equivalent is required, and what supplementary measures may be needed. Cite primary sources (regulation, Commission decision, regulator guidance, controlling case law) with pinpoint cites and verify currency — adequacy decisions, SCC versions, and required supplementary measures change through new Commission decisions, court rulings, and regulator guidance. Flag uncertainty for attorney verification.

If a transfer mechanism is missing and there is an international transfer, that is a 🔴 — there is no lawful transfer mechanism.

## Gate: signing a DPA

Reviewing a DPA is research. *Signing* it — or instructing someone to countersign on our behalf — is the consequential act.

**Before proceeding to sign or countersign a DPA (including returning an executed version, consenting to automatic execution on a counterparty platform, or instructing a signatory to execute):** Read `## Who's using this` in `../../profile/privacy-playbook.md`. If the Role is Non-lawyer:

> Signing a DPA is a legal act — it binds the company to specific data-protection obligations that flow to regulators and data subjects. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: counterparty, direction (we are processor / controller), the terms that deviate from the playbook and how they were resolved, any open fallback decisions, and the three things to ask the attorney before executing.]
>
> If you need to find a licensed attorney, solicitor, barrister, or other authorised legal professional in your jurisdiction: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes.

## Close with Next move

Close per the playbook's `## Outputs` → Next steps: **Next move** — 1–3 concrete actions, a named decision only if one is real, and a one-line offer to draft the follow-on artifact. No option menus.

## What this skill does not do

- It doesn't draft a DPA from scratch. If the answer is "use our template," pull the template from the matter's documents (playbook `## Seed documents`: none practice-wide).
- It doesn't do the Transfer Impact Assessment itself — it flags when one is needed.
- It doesn't decide whether to accept terms outside the fallbacks. It routes those per the escalation table.

## practice overlay

- Output in partner mode: bottom line first, prioritized, short. The
  partner can ask to dive deeper ("explain" / "dive deeper" / "full
  analysis").
- Report only issues that matter. If the workflow surfaced 30 comments and
  4 are meaningful, they see 4 (say "N minor points available on request").
  Materiality invariant: anything legally material always survives the cut.
- Distinguish negotiable points from low-value comments; recommend, don't
  enumerate.
- The playbook at `../../profile/privacy-playbook.md` is pre-configured;
  never prompt for setup. If an entry is missing or unfitting, state the
  assumption and proceed; matter documents override playbook defaults.
- Never create administrative work for the partner. Workspace/state maintenance is
  silent (see the playbook's Matter workspaces section).
- All guardrails in this skill and the playbook's Shared guardrails remain
  in force.
