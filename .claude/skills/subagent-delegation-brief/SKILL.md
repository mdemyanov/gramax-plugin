---
name: subagent-delegation-brief
description: Use when dispatching subagents (Task/Agent tool) in this repo — how to write the brief, pick model/effort per role, isolate parallel work, and verify the plugin version subagents are actually running. Load before writing a subagent brief, not after something goes wrong.
---

## Delegating to subagents

Quality comes not from a higher model tier but from the loop "brief → execution → review with
reproduction".

The review leg runs as a named instrument, not a composed brief: artefact reviews — the
specification delta, the BA/SA plan, the wave diff — dispatch via `scripts/author-free-review.sh`
with the fixed prompt `scripts/author-free-review-prompt.md` (capability
`review-without-author`); the reviewer's input is the artefacts plus the acceptance criteria.

### Brief rules — mandatory in every subagent call

Write every subagent brief in English regardless of the conversation's language — a short
fact-list, each claim with its command.

1. **The right to stop.** "Found a conflict with an already-accepted decision — do not decide it
   yourself: stop this branch of work, record it in the report with verbatim quotes from both
   sides, finish the rest". A refusal backed by quotes is a correct outcome: it is usually more
   correct than a task that would break an accepted ADR.
2. **Measure, don't carry over.** "Do not reuse numbers from someone else's research — measure
   yourself and name the command" — a carried-over number may describe a corpus that no longer
   exists. A measurement quoted in a permanent document is pinned to a commit
   **inside the command itself** (`git log <sha> …`), otherwise the task's own commits land between
   the measurement and the record.
3. **Mutation, not green.** "Break the implementation, show that the test fails": a test that
   cannot fail looks exactly like a test that passes. For a test-design task proving many
   mutations, build a throwaway reference implementation in scratchpad and run the mutation matrix
   against it before handing off — it catches defects in the locks themselves.

### The fourth rule — every number with the command it was obtained by

A brief is a fact list, not a retelling. Every number and every factual statement comes with an
executable command: not "`apply-overlay` calls two libraries" but
`grep -n "uv run" scripts/apply-overlay.sh`. This does not cancel the "measure, don't carry over"
rule — it changes the form of the re-measurement: **one command from the brief**, not research from
scratch — without it the agent reopens the call graph itself, at up to twice the tool calls.

**Citing a command is not the same as running it.** The obligation to run every command of the
brief falls on its AUTHOR, before sending it — not only on the reader who re-measures later; a
number the author never ran reaches the agent unchecked.

### The fifth rule — a diagnosis in a brief is a hypothesis, not an assignment

Name the OBSERVATION ("the lock does not redden on mutation X") and leave the cause to the role:
a brief that named ONE defect where there were two kept the second behind a fix that looked like
success. The closing check is set on the observation — run the same mutation again and require
the outcome to have changed, not the named cause to be gone.

### The sixth rule — "the blocker pre-exists the task" is proven by categories, not by `rc`

Red-before and red-after are equal in return code and different in composition: a refusal
category that moved 0 → 1 across the task is a NEW refusal the task added, whatever the total
says. A brief claiming a pre-existing blocker carries the per-category breakdown of the gate's
output before and after; an override without that breakdown may hide a refusal of a category
nobody mentioned.

### The seventh rule — verified facts are not re-derived

Rules 2 and 4 make every fact carry its command; they do not make the agent re-research the
fact. A fact the brief marks **[verified]** (`path:line`, a resolved identifier, a checked
signature — the command that verified it sits next to it) is USED, not re-established: run the
named command when you need the value live, but do not re-derive the surrounding picture by
search around it. In a measured session a third of a role's tool calls was exactly that
re-derivation of facts the coordinator had already verified. A [verified] fact that turns out
wrong on the spot is a reportable finding — quote both sides, do not silently mass re-verify.

### Test run — named files inside a task; the full suite is the coordinator's

A role runs only the test files of its own subject: `uv run --with pytest pytest tests/test_x.py -q`.
A run of the whole `tests/` inside a subagent is denied by `hooks/resource-discipline.py`
(ADR-102 Д3), so a brief never asks for it. The full suite belongs to the coordinator: parallel
`uv run --with pytest-xdist --with pytest pytest tests/ -q -n 8` during the wave, sequential
`uv run --with pytest pytest tests/ -q` before a merge into `stable` — the cost of a false green at
that boundary is higher than the minutes saved. A duration quoted in a brief is re-measured with a
command that carries its own `sha`: durations grow with the suite, not with the machine.

A mid-wave gate may slice a named family file per AC:
`uv run --with pytest pytest tests/test_qa1xx_<slug>.py -q -k 'ac2a or ac2b'` — the anchor is the
full lettered AC id in the test's name (`ac2a`, not the bare digit `ac2`: as a prefix it also
matches `ac20`…`ac28`). A per-AC run covers the named ACs only and never substitutes the release
ritual (ADR-137 Д5).

**Measurements taken while other agents are running are contended and are not comparable** — same
subject, same night: `gitleaks dir .` measured 41.3 s under load, 22.3 s quiet. Prefer countable
quantities the tool prints itself (scanned bytes, test count) over seconds; quoting seconds, say
what else was running.

Three runs do not prove parallel-safety forever: **caught a divergence between sequential and
parallel — stop and report it, that is a finding**. The wave's parallel run may go to the
background (the coordinator's, never a subagent's); the sequential run before a merge into
`stable` is mandatory — a passed parallel run does not skip it.

### Model and effort by role

| Role in the cycle | Model | Effort | Why |
|---|---|---|---|
| Coordinator (main-context) | Opus | medium | Deciding and checking; high is spent re-deriving what a grep gets cheaper |
| Task review and final branch review | Opus | high | Needs to **construct** a falsifying scenario, not just notice one. Every Critical of the epic came from here |
| Design (SA), ADR | Opus, passed as the call's `model`; the frontmatter default stays `sonnet` | high | Compatibility with a neighboring decision is the one thing a run cannot measure |
| Executors on a concrete brief (Dev, BA) | the role's regular tier | medium (ADR-116 Д5 — `low` is not a taken value; each role's frontmatter is the source) | The brief already carries the values; thinking is about the run, not about "what" |
| Scoped re-reviews of fixes | Sonnet | low–medium | The list of findings is given, the task is to check each item |

Each role declares its own `effort:` in its frontmatter; the call's `model` parameter can override the model, but there is no per-call `effort` parameter — `effort` always comes from the role's frontmatter.

Platform validity: on the base delivery platform (Claude Code) the frontmatter `model:` and `effort:` fields of a role are executed — both are live statements there.

On hosts that resolve the model at runtime (ZCode) the frontmatter statement is not applied; the per-provider difference registry owns validity — `docs/30-architecture/provider-declarations.md` (row 5, ADR-129).

Tier does not prevent factual errors: an Opus author gets numbers wrong as often as Sonnet — the command catches them, not the reasoning. Tier and effort are spent on **checking**, not on composing.

### Isolating parallel work

Parallel subagents in one working tree cause commit races. The trigger of isolation is
simultaneity, not what the agents edit: dispatch two or more agents in ONE message and give each
call `isolation: "worktree"` — the platform creates a copy per agent under `.claude/worktrees/<id>`
and returns its path and branch. The first action of every role in its copy is `git branch -m
<number>`, so that the branch name addresses the task. A single agent needs no copy. Reviewers
read and can work in parallel with anyone.

### Checking the environment on start

Role prompts arrive via plugin install, and the runtime can execute a previous version while the
repository holds the next one; comparing cache versions does not catch this — the cache lists what
was downloaded, not what is active. The working check: the first subagent's brief of the epic asks
to quote verbatim the `PROMPT-EDITION:` line of its own role prompt as the first line of the
report; compare it against `agents/<role>-agent.md`. The marker is language-independent (ASCII,
NA-EPIC-99): a paraphrase, a translation or a mismatching value means the runtime holds a cached
or translated prompt — update the plugin before the epic starts, or carry the key constraints in
every brief by hand.
