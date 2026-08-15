# The scenario harness

This plugin is prose. Its behavior is what a model does after reading that
prose, so the only honest test is a real session: `tests/run.sh` spawns
headless `claude -p` sessions, feeds them scenario prompts, and grades the
transcripts. There is no unit-testable layer underneath — a test that
asserts the markdown says "bottom line first" proves nothing about whether
the answer starts with one.

That buys realism at a price, and the price is listed under
[What this cannot tell you](#what-this-cannot-tell-you). Read it before
treating a green run as proof of anything.

## Running

```bash
tests/run.sh --list              # the scenario table
tests/run.sh persona             # one scenario by id
tests/run.sh --all               # static checks + the whole battery
tests/run.sh --all --partial     # accept a run that skips scenarios
tests/run.sh --all --no-web      # drop the web-research scenarios
```

Scenarios cost tokens and minutes. Run the ones your change touches during
development; `--all` is the gate.

| Variable | Default | Purpose |
|---|---|---|
| `PC_CLAUDE_BIN` | first `claude` on PATH | binary under test |
| `PC_MODEL` | `opus` | model for every session |
| `PC_STATE_DIR` | per-run dir under the results dir | plugin state root |
| `PC_RESULTS_ROOT` | `tests/.results` | where transcripts land |
| `PC_TURN_TIMEOUT` | `900` | per-turn wall-clock ceiling, seconds |
| `PC_MAX_COST_USD` | `10` | cumulative spend ceiling for the run |

## Three guarantees, and how each is enforced

**Your real matters are untouchable.** The plugin resolves its state root
from `PRIVACY_COUNSEL_HOME`, falling back to `~/.claude/privacy-counsel`,
which holds real client work. Every run redirects that variable to a fresh
directory under the results dir. Nothing a scenario does can reach a real
matter, and `init_state_root` refuses to start if the root resolves to the
production path.

This replaced a `--reset-state` flag that `rm -rf`'d the matter slugs
`acme`, `beta`, and `general` out of the production directory. `general`
is the practice-level default slug. The flag is gone; a per-run root has
nothing to reset.

**Sessions grade the tree you are sitting in.** Without `--plugin-dir`, a
headless session loads whatever privacy-counsel is *installed* — which on
a dev box points at one specific worktree. Run the suite from any other
worktree and it silently grades the wrong code. Sessions now load
`REPO_ROOT` explicitly and disable installed copies through `--settings`.

Since that is a claim about flag behavior rather than a proof, `preflight()`
runs first and proves it: one session quotes the "Practice playbook" and
"Mutable state root" lines from its own status block, and the run aborts
unless both point at this tree and this run's state root. One session's
cost, spent so the other twenty mean something.

**A skipped scenario is not a pass.** Scenarios exit 3 when they do not
run — `pending` (waiting on a later ticket) or web-tagged under `--no-web`.
`--all` fails if anything was skipped unless you pass `--partial`, and the
summary line distinguishes:

- `ALL GREEN` — every scenario ran, every machine assertion passed
- `PARTIAL PASS` — what ran passed, some scenarios did not run
- `INCOMPLETE` — scenarios were skipped and `--partial` was not passed
- `FAILURES` — assertions failed

Ticket 09 gates on this exit code, so the distinction is the point.

## What this cannot tell you

**Machine assertions and human criteria are different things.** `assert_*`
moves the exit code. `criteria()` prints a line for a human to grade against
the saved transcript and never fails the run. A harness that claims to
automatically grade "is this in the house register" is lying about what it
knows. Reading the criteria after a green run is part of the gate, not
optional polish.

**A green run is one sample.** Each assertion rests on a single live
session. The model is pinned and the run records a manifest (commit, dirty
file count, model, CLI version, state root, cost cap) so a saved result
stays interpretable, but stochastic variance is real: one pass can hide a
regression and one failure can be noise. Re-run a surprising result before
believing it.

**Some things cannot be tested headlessly at all.** The command picker,
plugin disable/enable, concurrent sessions, and the first-write permission
prompt need a human in the Cowork UI. They live in `TESTING.md` under
manual checks and are not represented here.

**The plugin-binding fix is structurally sound but not yet live-verified.**
`--plugin-dir` plus `--settings` is the intended mechanism and `preflight()`
is designed to catch it failing. As of this commit no live run has executed,
so the first `tests/run.sh persona` is also the first real test of the
binding itself. If preflight fails, believe preflight.

## Writing a scenario

One file per scenario in `tests/scenarios/`, sourced by the runner. Metadata
first, then a `scenario_run` function:

```bash
SCENARIO_ID="dpa-review"
SCENARIO_TITLE="DPA review shape"
SCENARIO_STATUS="active"          # or "pending" while a ticket is unbuilt
SCENARIO_TAGS="core"              # add "state" if it writes, "web" if it searches
SCENARIO_TOOLS="Read,Glob,Grep"   # narrowest grant that lets the work happen
SCENARIO_ADD_STATE=1              # pre-create the state root and --add-dir it
SCENARIO_BLOCKED_BY="ticket 03"   # required when pending

scenario_run() {
  turn t1 "the prompt"            # fresh session; the hook fires
  next t2 "a follow-up"           # resumes t1's session
  assert_match t1 "regex" "what this proves"
  criteria "What a human must check in the transcript."
}
```

Helpers: `assert_match`, `assert_absent`, `assert_head_match`,
`assert_head_absent`, `assert_words_max`, `assert_words_min`,
`assert_words_grew`, `assert_path`, `assert_no_path`,
`assert_path_nonempty`, `assert_file_match`, `assert_file_absent_match`.

Two rules worth stating because both were violated before:

1. **`SCENARIO_ADD_STATE=1` is a grant, not a default.** Leaving it off is
   how you test the blocked-write path — but then assert BOTH that nothing
   persisted and that the session disclosed the failed save. "Degraded
   gracefully" and "never tried" produce identical output otherwise.
2. **A failed turn aborts the scenario.** Later turns are skipped rather
   than run against wrong context. Do not write a scenario that expects to
   continue past a failure.

## Changing an assertion costs nothing

Assertions read saved files, so a changed assertion can be re-graded against
a previous run's transcripts without spending a session. Source `lib.sh`
with `RESULT_DIR`, `STATE_DIR` and `REPO_ROOT` pointed at an existing
results directory, call the assertion, read the PASS/FAIL.

Do this before re-running. Roughly half the failures in practice are the
assertion being wrong rather than the plugin — one of these asserted that a
correct answer was wrong because it *mentioned* the default it had
overridden, which the provenance rule specifically asks for. Replaying is
free; a scenario is not.

## Results

`tests/.results/<stamp>/` holds `manifest.txt`, `cost.tsv`, and per-scenario
directories with `<label>.json` (raw envelope), `.txt` (assistant text),
`.err`, and `.prompt.txt`. The state root for the run is `state/` in the
same directory — inspect it to see exactly what the sessions wrote.
