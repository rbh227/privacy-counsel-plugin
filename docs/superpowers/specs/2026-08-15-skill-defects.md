# Spec — skill defects, v1 remediation

**Status:** ready-for-agent
**Depends on:** tickets 01–08 (landed); the public repo (published)

## Problem Statement

The partner installs the plugin and asks it to do real work. In several
places it will answer confidently and be wrong in ways he cannot see from
the answer.

- He asks it to review a vendor's AI terms for a client. It reports that the
  terms conflict with "our AI policy" and recommends redlines on that basis.
  No such policy exists for that client — the plugin is reading the
  practice's *advice to clients* as if it were the client's adopted policy.
  He forwards a redline justified by a policy his client never wrote.
- He runs a regulatory sweep. It reports what moved, filtered by
  materiality, and says nothing else. Most of his watchlist — state
  regulators, EU DPAs, AI regimes — was never queried, because the feed
  configuration those categories need does not exist. Silence reads as "all
  quiet".
- He asks "what AI systems does this client have?" and gets a complete-looking
  answer covering one matter. The same client's systems recorded in a
  different matter are invisible, and system IDs collide between them.
- He drops twelve PDFs and says "take a look". Four skills could claim that
  and nothing decides between them, so the same twelve files produce a
  briefing one day and a citation table the next.
- Several skills tell him to edit a file inside the plugin directory. The
  next plugin update overwrites it.

Underneath all of these: eight of the twenty skills have never executed once
in a live session, and nobody has ever installed the plugin from the
published repository.

## Solution

Close the defects that make the plugin confidently wrong, then verify the
skills that have never run.

Three principles decide most of the individual fixes:

1. **The firm is not the client.** Anything the plugin calls "our policy",
   "our position", or "our approved vendors" has to resolve to a specific
   source — the practice playbook (the firm's default advice), the active
   matter (this client's actual position), or neither. Where it resolves to
   neither, the honest output is "not assessed", not a finding.
2. **Silence must be attributable.** A skill that reports nothing must be
   able to say whether it looked. Coverage gaps, uncovered categories, and
   unqueried sources get named in the output rather than collapsing into an
   empty result.
3. **Durable state goes outside the plugin.** No skill instructs an edit to
   a file a plugin update will overwrite.

## User Stories

1. As a privacy partner, I want vendor AI terms compared against MY CLIENT'S actual AI policy, so that a redline I send is justified by a document the client has adopted.
2. As a privacy partner, I want the plugin to say "no client AI policy on file — policy consistency not assessed" when the matter has none, so that I do not present a fabricated conflict as a finding.
3. As a privacy partner, I want the practice playbook's AI positions labelled as the firm's proposed baseline, so that I can offer them to a client as advice rather than cite them as the client's commitment.
4. As a privacy partner, I want an "approved vendor list" finding only where the active matter actually contains one, so that the plugin does not invent a procurement control the client does not operate.
5. As a privacy partner, I want an AI impact assessment to diff against the client's own commitments where they exist, so that the policy-consistency section means something.
6. As a privacy partner, I want a regulatory sweep to resolve every watchlist category to real sources, so that "nothing material" is a finding rather than an artefact of never having looked.
7. As a privacy partner, I want each watched category marked covered or uncovered in the digest, so that I can see at a glance which half of my footprint was actually queried.
8. As a privacy partner, I want the whole sweep marked partial whenever any watched category has no successful source, so that a partial sweep can never read as a complete one.
9. As a privacy partner, I want the seeded source catalogue used automatically for categories in my footprint, so that a fresh install sweeps EU and state regulators without me configuring feeds.
10. As a privacy partner, I want to be told once, plainly, which categories have no configured source, so that I can decide whether to add them rather than discovering the gap months later.
11. As a privacy partner, I want durable changes written to my overrides file, so that updating the plugin never silently reverts my configuration.
12. As a privacy partner, I want no skill to instruct me to edit a file inside the plugin, so that I am never told to make a change that will be overwritten.
13. As a privacy partner, I want commands referred to by their real names, so that "run setup" is something I can actually type.
14. As a privacy partner, I want a client's AI inventory to be answerable across their matters, or to be told plainly that it is not, so that "what systems do we have" is never answered completely-looking but partial.
15. As a privacy partner, I want AI system IDs that do not collide between two matters for the same client, so that carrying a register across does not produce two sys-001s.
16. As a privacy partner, I want defined storage when no matter applies, so that practice-level AI work is not silently dropped or written somewhere arbitrary.
17. As a privacy partner, I want every skill that reviews many items to report only what matters, so that no skill hands me thirty comments when four are meaningful.
18. As a privacy partner, I want a skill's output template and its practice overlay to agree, so that the model does not follow one and ignore the other.
19. As a privacy partner, I want withheld minor points offered in one line and not enumerated anyway, so that "N minor points available on request" is a real offer rather than a preamble to a dump.
20. As a privacy partner, I want a cited cell from a PDF to carry a page or section I can turn to, so that verification is fast enough to actually happen.
21. As a privacy partner, I want to be told when a PDF is scanned or unreadable rather than getting quiet gaps, so that an OCR failure is not indistinguishable from an absent clause.
22. As a privacy partner, I want to drop a pile of PDFs with no instruction and get useful work, so that the plugin fits how I actually work.
23. As a privacy partner, I want the plugin to name the read it is taking in one line before it starts, so that I can redirect it in three words if it guessed wrong.
24. As a privacy partner, I want it NOT to interrogate me about what I want done with the documents, so that dropping files stays faster than explaining.
25. As a privacy partner, I want every skill exercised at least once before I rely on it, so that the first real matter is not the first execution.
26. As a privacy partner, I want the published install path tested, so that the two commands in the README work when I type them.
27. As a maintainer, I want a static check that no shipped skill instructs editing the plugin directory, so that this class cannot come back with the next import.
28. As a maintainer, I want the client-versus-firm distinction covered by a live scenario, so that a future edit cannot quietly reintroduce the conflation.
29. As a maintainer, I want the multi-document routing rule covered by a scenario, so that the routing stays deterministic enough to test.
30. As a maintainer, I want the skills that have never run added to the standard battery, so that coverage is a property of the gate rather than of who remembered.

## Implementation Decisions

**Client-versus-firm separation (vendor-ai-review, aia-generation).**
The playbook's `## AI governance` → `AI policy commitments` is renamed and
reframed as the practice's *proposed baseline* for advising clients, and
explicitly labelled as not being any client's adopted policy. Both consuming
skills load the active matter's client AI policy first. Where the matter has
none, the policy-consistency section reports NOT ASSESSED and asks for the
policy; it does not fall through to the baseline and it does not generate
mismatch findings. The baseline may be *offered* ("your client has no AI
policy on file; here is the position we normally advise") but never asserted
as the client's. The "approved vendor list" and "blocklist" checks fire only
where the active matter supplies one.

**Sweep coverage (reg-feed-watcher).**
Each watchlist and footprint entry resolves to one or more sources in
`references/source-catalog.md`. The skill maintains a coverage matrix —
category, sources attempted, sources succeeded — and emits it with the
digest. A category with zero successful sources marks the whole sweep
PARTIAL, and the digest never says "nothing material" for a category it did
not query. The Federal-Register-only fallback stops being a silent default
and becomes a stated limitation naming what it does not cover.

**No plugin-directory edits (all skills).**
Every instruction to edit `profile/privacy-playbook.md` is replaced by the
overrides mechanism, and every bare command name (`setup`) becomes
`/privacy-counsel:setup`. A static check enforces the first half: no shipped
skill may instruct an edit to a path inside the plugin.

**AI register scope (ai-inventory).**
v1 declares the register engagement-local rather than implying a client
system of record. System IDs are qualified by matter so two matters cannot
produce colliding IDs. Storage when no matter applies is defined explicitly
(practice-level path under the state root), rather than left undefined.
"What systems do we have" answers with an explicit scope line naming the
matter it covers. A client-scoped registry is deliberately deferred — it is
a confidentiality-model decision, not an engineering one, and is recorded in
Out of Scope.

**Overlay/template agreement (use-case-triage, reg-gap-analysis,
pia-generation, dsar-response, and any other skill carrying the
minor-points overlay).**
Where a skill's output template says "for each" and its practice overlay
says "report only what matters", the prioritization contract moves into the
template block itself — the template is the concrete instruction the model
follows, and the overlay loses to it. dpa-review and vendor-ai-review are
already fixed and are the reference pattern.

**Source location for PDFs (tabular-review, diligence-issue-extraction).**
The verbatim-quote contract gains a location convention: section or clause
number where the document has one, page number where it does not, and both
where available. An unreadable or image-only PDF produces the explicit
`needs_review` state naming the extraction failure — never a quiet
`not_present`, which would be indistinguishable from a genuinely absent
clause.

**Multi-document routing (playbook, always-on).**
A short routing rule in the playbook covers a document set arriving with no
stated intent: same question across every document → tabular review; find
the problems → diligence extraction; orient me → briefing; one document's
history → amendment trace. The rule names the read taken in one line and
proceeds. It explicitly does not interrogate the partner about intent.

## Testing Decisions

A good test here asserts external behavior — what a session says and what
lands on disk — never the presence of a phrase in a SKILL.md. Asserting
that the markdown contains "not assessed" proves nothing about whether a
session says it.

**Primary seam: the existing scenario harness** (`tests/run.sh`,
`tests/scenarios/`). Every behavioral defect above is verified by a live
session, because the plugin's behavior IS model behavior. Prior art:
scenarios 11 and 22, which caught real defects and whose failures were
correctly re-graded against saved transcripts.

- Scenario 12 (`vendor-ai-review`) gains assertions that a matter with no
  client AI policy produces NOT ASSESSED and no fabricated conflict, and
  that a matter WITH one is diffed against that policy rather than the
  baseline.
- Scenario 18 (`reg-feed-watcher`) asserts a coverage matrix in the digest,
  PARTIAL marking when a category has no successful source, and the absence
  of "nothing material" for an unqueried category.
- Scenario 13 (`ai-inventory`) gains a second-matter case asserting
  non-colliding IDs and an explicit scope line.
- Scenario 15 (`tabular-review`) gains an image-only PDF fixture asserting
  `needs_review` with a named extraction failure, distinct from
  `not_present`.
- A new scenario covers multi-document routing: a set of documents with no
  stated intent, asserting the session names its read in one line and
  produces work rather than a clarifying question.

**Secondary seam: `scripts/static-checks.sh`** — token-free, runs every
commit. Only for defects that are mechanically detectable in text: the
plugin-directory-edit instruction, and bare command names. Prior art:
checks 7a–7c and 9, each with negative controls proving they fire.

**The install path** is verified by a scripted install into a sandboxed
HOME, asserting the marketplace resolves, the plugin installs, and a session
started under it reports the expected component status. This is the one
place a shell test beats a scenario, because the thing under test is
resolution and installation rather than behavior.

Every scenario currently at `active` but never executed (12–19) runs as part
of closing this spec. Failures are replayed against saved transcripts before
being treated as plugin defects — in the two scenarios run so far, two of
three failures were bad assertions.

## Out of Scope

- **A client-scoped AI registry spanning matters.** This is a professional-
  responsibility decision about whether the confidentiality wall runs between
  clients or between matters, and it belongs to the partner, not to an
  implementation ticket. v1 declares the register engagement-local.
- **Automated OCR of scanned PDFs.** The requirement here is to fail loudly,
  not to extract text from images.
- **Paid regulatory feed integrations.** Tier 2 stays configuration-only.
- **Re-syncing any vendored skill with upstream.** The overlay policy stands.
- **Manual checks M1–M6.** They need a human in the Cowork UI and cannot be
  automated; they remain a delivery checklist item.

## Further Notes

The defects cluster by origin, which is worth knowing when fixing them. The
firm-versus-client confusions all come from upstream skills written for an
in-house legal team, where "our policy" was unambiguous. The adaptation
rewired the file paths and missed the pronoun. Expect more of this class in
any future import, and check for it specifically rather than trusting a path
rewrite.

The sweep-coverage and register-scope defects share a shape too: a skill
that cannot distinguish "I looked and found nothing" from "I did not look".
That distinction is worth treating as a house rule rather than three
separate fixes.

Two defects in this spec were found only because a Codex review dropped mid-
run and the partial log was read from disk. Reviews that fail are worth
reading anyway.
