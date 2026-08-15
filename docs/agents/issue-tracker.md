# Issue tracker

Local-files tracker (no hosted tracker until the public repo exists).

- Tickets live at `.scratch/privacy-counsel-v1/issues/<NN>-<slug>.md`, one
  file per ticket, numbered in dependency order. Ticket files ARE committed
  (the `.scratch/runs/` workspace is not).
- A ticket's fields: What to build / Blocked by / Seams / Model / Status /
  acceptance-criteria checklist.
- Status lifecycle: `ready-for-agent` → `in-progress` → `done` (or
  `parked — <reason>`).

## Closing a ticket

1. Set `Status: done`.
2. Append a `**Closed:**` line with the commit SHA(s) and a one-line
   summary.
3. Tick the acceptance-criteria boxes that the evidence supports (leave
   unticked ones unticked and say why in the Closed line).
4. Commit the ticket file + `STATE.md` together as a metadata commit.

## Labels

No hosted labels; the ticket's `Model:` field carries the fable/sonnet
designation and `Status:` carries triage state.
