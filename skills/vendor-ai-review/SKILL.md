---
user-invocable: false
name: vendor-ai-review
description: >
  Review vendor AI terms — agreement, addendum, or ToS AI provisions — against your
  governance positions; flag training-on-data, liability, model changes, and AI policy
  consistency. Use when user says "review this AI agreement", "check OpenAI terms",
  "what did we agree to with [vendor]", "vendor sent an AI addendum", "is this AI
  contract okay", or attaches vendor AI terms.
argument-hint: "[vendor name, or attach the contract]"
---
<!-- MODIFIED from anthropics/claude-for-legal (Apache-2.0), commit 4a6c651 — see VENDORED.md.
Changes: configuration redirected to this plugin's pre-filled practice playbook (../../profile/privacy-playbook.md)
and the practice overrides file, setup/cold-start gates removed (playbook is always configured),
upstream /ai-governance-legal:* command handoffs replaced with natural-language skill references,
mutable state moved under the state root named in the session-start status block, practice overlay appended. -->

# /vendor-ai-review

1. Read `../../profile/privacy-playbook.md` → `## Vendor AI governance` and `## AI governance`, plus the practice overrides file.
2. Use the framework below.
3. Confirm document type (AI addendum / main agreement AI provisions / ToS). If only an AUP was provided, ask for the full terms.
4. Term-by-term review: training on data, confidentiality of inputs, model changes, output IP, liability, incident notification, human review rights, use restrictions, audit rights.
5. AI addendum gap check if DPA exists but no AI addendum.
6. AI policy consistency diff vs. `../../profile/privacy-playbook.md`.
7. Output: bottom line, term-by-term, recommended redlines, if-they-won't-move routing.

Triggered from plain language — "review these vendor AI terms", "check
what we agreed to with this AI vendor" — with the terms pasted or attached.

---

## Matter context

**Matter context.** Matter workspaces are enabled and silent (see the playbook's `## Matter workspaces`; the active matter is SESSION-scoped — resolved from this session's own context against the registry in `~/.claude/privacy-counsel/state.md`; any legacy `Active matter:` line found in state.md is stale — ignore it). Infer the active matter by exact, unique client/matter match; when two matters could both fit, STOP and confirm before touching matter files. Load the active matter's `matter.md` for matter-specific context and overrides. Write deliverables to `~/.claude/privacy-counsel/matters/<matter-slug>/outputs/` (matter-slug `general` when no matter applies). Never read another matter's files — cross-matter context is off; client confidentiality between matters is absolute.

---

## Purpose

Vendor AI terms are where governance positions actually get tested. The
playbook records what the client *wants*. This skill checks what they
*agreed to* — and flags the gaps between those two things.

The direction here is always the same: we are the deployer or buyer reviewing the
vendor's terms. This is the opposite posture from the DPA review controller/processor
question — there's no flip.

What varies is the *input*:
- A standalone AI agreement or AI addendum (most structured)
- A vendor's universal terms of service with AI provisions embedded (often buried)
- An acceptable use policy (tells you what you can't do; says nothing about what
  the vendor can do with your data or outputs)
- A combination — master agreement + DPA + AI addendum (common for serious enterprise
  AI vendors)

When there's a DPA already in place, this review complements it — it's not a
substitute. The DPA governs data protection obligations; the AI terms govern
model-specific rights and risks. Both need to be reviewed.

---

## Load the playbook

Read `../../profile/privacy-playbook.md` → `## Vendor AI governance`. Also read `## AI policy commitments`
— vendor terms can't be consistent with a use restriction our own policy imposes if
we've agreed to something different.

Read the practice overrides file alongside it — `## Overrides` governs which
source wins where both speak.

The playbook is pre-configured and always considered CONFIGURED. Never
prompt for setup, never offer a "provisional" mode, and never tell the
partner to run an interview. Where the playbook has no position on a term,
state the assumption you are making and proceed.

---

## Before reading the document

If the user hasn't shared the actual vendor terms, ask:

> "Can you share the vendor's AI terms? The most useful thing is the actual contract
> language — the AI addendum if there is one, or the main agreement with AI provisions
> highlighted. An acceptable use policy alone won't tell us what the vendor can do
> with our inputs; it only tells us what we're allowed to do."

If they share an acceptable use policy only:
> "This is the acceptable use policy — it tells us what we can't do with the vendor's
> AI. That's useful context, but it doesn't address the commercial terms: whether
> the vendor can train on our data, what their liability is for AI errors, whether
> they notify us when the model changes. Do you have the service agreement or AI
> addendum?"

---

## The term-by-term review

### Core AI-specific terms (check every vendor AI agreement)

Review each term below. For each, extract what the vendor's contract actually says and compare it against the position in `../../profile/privacy-playbook.md` → `## Vendor AI governance` (standard / acceptable fallback / automatic no). The default positions come from the team's playbook, not from this skill.

| Term | What to look for |
|---|---|
| **Training on our data** | Does the vendor use our inputs to train, fine-tune, or improve models? Is there an explicit opt-out or prohibition? Is training opt-in or opt-out by default? |
| **Confidentiality of inputs** | Are our prompts, documents, and data confidential? Any "quality review" or human-review carveouts that would let vendor staff read inputs? |
| **Model changes** | Any notice obligation for material changes to the model? Version pinning available? |
| **Output ownership / IP** | Who owns AI-generated content? Any license-back to the vendor on outputs? Any IP indemnity? |
| **Liability for outputs** | Does the vendor accept any liability if the AI produces harmful, incorrect, or infringing outputs? Cap structure? Carve-outs? |
| **Incident notification** | How and when are we notified if the AI system fails, is compromised, or produces systematic errors affecting us? |
| **Human review rights** | Can we require human review of outputs in specific cases? Can we appeal or dispute an AI decision? |
| **Use restrictions** | What are we prohibited from doing? Does it match what we actually want to use the tool for? Any definitional terms (e.g., "automated decision-making") that could sweep in our intended uses? |
| **Audit / auditability** | SOC 2, third-party audits, bias testing results — any audit rights? |
| **Subprocessors / model providers** | Does the vendor use sub-vendors for the model? Are they disclosed? Whose terms govern? |
| **Data residency** | Where is our data processed? Where does it go for inference? |
| **Term and termination** | What happens to our data when we terminate? Deletion timelines? |
| **Stacked-vendor accountability** | Is this vendor the model provider (e.g., Anthropic, OpenAI, Google, Meta), or are they a deployer of someone else's model (e.g., a SaaS wrapper of Claude, ChatGPT, or Gemini) or a reseller of infrastructure-hosted foundation models (Anthropic-on-Bedrock, Claude-on-Vertex, OpenAI-on-Azure)? If the latter: there are TWO vendors' terms in play — the one you're reviewing, plus the upstream model provider's terms. Identify (a) whose terms govern training on inputs, retention, and safety, (b) who is contractually liable for model behavior, and (c) whether each upstream commitment (e.g., "no training on inputs") is flowed down to you, or remains between the vendor and the upstream provider only. Flag any clause where one party disclaims responsibility for the other (e.g., "Anthropic is not responsible for Bedrock or any other services it receives from AWS"; "Azure disclaims responsibility for OpenAI model outputs") and whether the counter-party's contract closes the gap. Do not review the two contracts in isolation. |

If `../../profile/privacy-playbook.md` doesn't define a position for a term on this list, state the assumption you are making and carry on with the review — do not stop. Raise it once at the end: "The playbook has no position on [term]; I assumed [X]. Want that as your standard going forward?" On confirmation it persists as a keyed line in the practice overrides file, per the playbook's `## Overrides`. Never edit the playbook itself: it ships with the plugin and an update would overwrite the edit.

---

## Playbook comparison

For each term above, compare what we found to the positions in `../../profile/privacy-playbook.md`.

**Output format for each term:**

> **[Term name]**
> 🟢 / 🟡 / 🟠 / 🔴
> **Vendor says:** [summary of what the contract actually says]
> **Our position:** [from `../../profile/privacy-playbook.md`]
> **Gap:** [specific delta — or "Aligned"]
> **Proposed fix:** [specific redline language, or "escalate — outside fallback"]

Use the severity ratings consistently (calibrated against `../../profile/privacy-playbook.md` positions):

- 🟢 **Aligned** — at or better than the standard position in the playbook.
- 🟡 **Note** — within fallback but worse than standard; flag for awareness, not a blocker.
- 🟠 **Significant** — outside standard position but within fallback; needs redline before signing.
- 🔴 **Critical** — outside fallback; deployment should not proceed without resolution. Escalate per `../../profile/privacy-playbook.md`.

---

## AI addendum gap check

**If the vendor has a DPA but no AI addendum:**

> "There's a DPA in place but no AI-specific addendum. The DPA covers data protection
> obligations but doesn't address: training on our data, model change notification,
> liability for AI outputs, or incident notification for AI system failures.
>
> For a [Standard / Elevated / High] tier use case, this gap is [acceptable at
> Standard tier / a blocker at Elevated or High tier]. Recommend requesting an
> AI addendum or at minimum negotiating AI-specific terms into the next renewal."

**If there are no AI terms at all:**

> "There are no AI-specific terms in this agreement. The vendor is providing an
> AI-powered service under general service terms — which means we have no
> contractual protection on the highest-risk AI governance items (training, liability,
> model changes). This is a 🔴 for any Elevated or High tier use case."

---

## AI policy consistency check

Cross-check the vendor's terms against our AI policy commitments in `../../profile/privacy-playbook.md`.

Common conflicts:
- Our policy prohibits vendor training on our data — the vendor's terms permit it by
  default. (Contract needs explicit prohibition or opt-out confirmation.)
- Our policy requires human review for certain use cases — vendor's terms say AI outputs
  are final. (Workflow needs to impose the human step, not the vendor terms.)
- Our approved vendor list doesn't include this vendor — or blocklist does.
- Our policy requires disclosure to affected parties — vendor's terms impose a
  confidentiality obligation on AI system capabilities that would prevent disclosure.

Flag every mismatch. One of them has to change.

---

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

**Before recommending signature of a vendor AI agreement (the version the company will execute):** Read `## Who's using this` in `../../profile/privacy-playbook.md`. If the Role is Non-lawyer:

> Signing this vendor AI agreement has legal consequences. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the vendor and the use case, the key terms reviewed (data use, liability, auditability, model change, human review), where vendor positions diverge from policy, what's being accepted, what could go wrong, what to ask the attorney.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes. Review/redline drafts for attorney consideration do not require the gate — signature does.

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

*This review is derived from vendor contract terms that are typically confidential under NDA, and it may itself be privileged. It inherits the source's confidentiality and privilege status. Distributing it beyond the privilege circle (e.g., forwarding to the vendor, sharing in an open channel) can waive privilege and breach the NDA. Mark, store, and route accordingly.*

# Vendor AI Review: [Vendor Name]

**Document reviewed:** [AI addendum / main agreement AI provisions / ToS]
**Reviewed:** [date]
**Use case(s):** [what we're deploying this vendor's AI for]
**Governance tier:** [Standard / Elevated / High]

---

## Bottom line

[Two sentences. Can we deploy under these terms? What has to change first?]

**Issues:** [N]🔴 [N]🟠 [N]🟡 [N]🟢

---

## Term-by-term

[Only the terms worth the partner's attention — vendor position, our
position, gap, severity, proposed fix. Review every term in the table
above; report the ones that matter. Close with one line, "N minor points
available on request", covering what you reviewed and left out — do not
table or list them. Materiality invariant: anything legally material
survives the cut however dull.]

---

## AI addendum status

[Present / Absent — and what that means for this deployment]

---

## AI policy consistency

[🟢 Consistent | 🟡 Flags: list]

---

## Recommended redlines

[Consolidated draft redlines. Review with counsel before sending externally. For critical
issues where no fallback exists, flag for escalation rather than proposing language.]

---

## If they won't move

[For each 🔴 and 🟠: the fallback from `../../profile/privacy-playbook.md`, or "escalate — outside fallback"
and routing per escalation table]
```

---

## Practical notes

**The training-on-data clause is the one most people miss.**
Vendor AI terms have historically varied widely on whether API inputs can be used
to train or improve models — some vendors permit it by default, others prohibit it,
and many have changed their position over time. Do not assume any particular vendor's
current stance without reading the specific agreement in front of you. This is almost
always the most important term for any company with confidential or sensitive data,
and it must be confirmed in writing, not assumed from reputation or prior experience.

**Map the AI stack.** Modern AI deployments are layered. Before reviewing terms, map the layers:
1. **End-user SaaS application** (e.g., a legal tech tool, a CRM with AI scoring, a document assistant) — the tool your org signs up for
2. **API gateway / orchestration layer** (e.g., Azure OpenAI Service, AWS Bedrock, Google Vertex, LangChain-hosted) — often invisible, always has its own terms
3. **Model provider** (e.g., Anthropic, OpenAI, Google, Meta) — the LLM
4. **Hosted knowledge base / RAG source** (e.g., a vector database, a third-party data corpus, a retrieval service) — the data Claude reads from
5. **Additional subprocessors** — analytics, logging, fine-tuning partners

Ask: "Walk me through the stack — what does [SaaS tool] use under the hood? Is it built on a cloud AI service? Does it call a model provider directly or through a gateway? Does it use a hosted knowledge base?" Then review terms at EACH layer, not just the top.

Each handoff between layers is a flow-down risk. A commitment at layer 1 ("we won't train on your data") means nothing if layer 3's terms say otherwise and layer 1 never flowed the commitment down.

**Flow-down test.** For each flagged stacked-vendor term — especially training-on-data, data retention, subprocessor changes, and liability — don't just flag "check upstream terms." DO THE CHECK:

1. **Search the contract for flow-down language.** Look for: "subprocessor obligations no less protective than," "flow-down of data commitments," "back-to-back terms," "Provider shall ensure that its subprocessors are bound by," "equivalent obligations."
2. **If present:** Quote it, verify it covers the specific flagged term, and flag whether it's enforceable (who can enforce it — you, or only the intermediate vendor?).
3. **If absent:** Produce a specific redline requiring it:
   > "Add to §[X]: Provider shall ensure that any third-party model providers, infrastructure providers, or subprocessors used in delivering the Services are bound by obligations with respect to [Customer Data / AI training / data retention / confidentiality] no less protective than those set forth in this Agreement, and shall be responsible for any breach of this Agreement caused by such third parties."
4. **Flag the gap with a severity:** 🔴 if the term is training-on-data or liability and there's no flow-down; 🟡 if the term is less sensitive or there's partial flow-down.

"Escalate and check upstream" is where compliance dies. Produce the test and the redline.

**Acceptable use policies flip the frame.**
AUPs tell you what you can't do; they don't tell you what the vendor can do.
Don't let a clean AUP review substitute for reading the data use and liability terms.

**Renewals are leverage points.**
If the current agreement is unfavorable and the vendor won't renegotiate mid-term,
document the gaps now and flag them for the renewal. Flag to procurement:
"This renewal should not close without AI addendum addressing [list]."

**Builder context adds a layer.**
If the company is a builder using a vendor's model as a foundation, the vendor's terms
also govern what the company can offer its own customers. Some terms prohibit certain
downstream uses. Check use restrictions against the product roadmap, not just current
internal workflows.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per `../../profile/privacy-playbook.md` `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't review the DPA provisions of the same agreement — run
  `the dpa-review skill`, for that.
- It doesn't decide whether to accept terms outside the fallbacks. It routes those
  per the escalation table in `../../profile/privacy-playbook.md`.
- It doesn't evaluate vendor security posture beyond what's in the agreement —
  that's a security team function.

---

## practice overlay

- Output in partner mode: bottom line first, prioritized, short. The
  partner can ask to dive deeper ("explain" / "dive deeper" / "full
  analysis").
- Report only what matters. If the workflow surfaced 30 findings and 4 are
  meaningful, they see 4 — close with one line, "N minor points available on
  request", and do NOT table, list, or summarize the withheld ones. Offering
  them and enumerating them anyway is the same as dumping. Materiality
  invariant: anything legally material always survives the cut.
- Distinguish negotiable points from low-value comments; recommend, don't
  enumerate.
- The playbook at `../../profile/privacy-playbook.md` is pre-configured;
  never prompt for setup. If an entry is missing or unfitting, state the
  assumption and proceed. Precedence runs through the playbook's
  `## Overrides`: in-session correction, then the active matter's keyed
  overrides, then the practice overrides file, then the playbook default.
- We are OUTSIDE COUNSEL. The "company" in any upstream framing is the
  CLIENT of the active matter, not the firm; posture, footprint, and risk
  appetite are matter-specific.
- Never create administrative work for the partner. Workspace/state
  maintenance is silent (see the playbook's `## Matter workspaces`).
- All guardrails in this skill and the playbook's Shared guardrails remain
  in force.
