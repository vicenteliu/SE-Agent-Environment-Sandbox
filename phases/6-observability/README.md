# Phase 6 — Observability and trace debugging

> What is kept from a rollout, and how one failure is found among hundreds.

🧭 **Specified, not run.** The minimum tier can emit a trace for one rollout; it cannot verify
retention, indexing or search across hundreds, which is the whole phase.

| # | Hop | Marker | What it answers |
|---|---|---|---|
| 1 | **The per-rollout trace** | 🧭 | What one rollout leaves behind, in what shape |
| 2 | **Retention as a stated rule** | 🧭 | What is dropped, decided in advance |
| 3 | **Finding one failure across hundreds** | 🧭 | Search by what the trace contains, not by when it happened |
| 4 | **Replay from a snapshot** | 🧭 | Turning a trace into a reproducible rollout again |

## Prerequisites

- Rollout identity established in phase 1 and preserved across phase 2's branches.
- A place to put traces whose cost is in phase 3's objective.

## Hop 1 — the per-rollout trace

Identity · tier · every action the agent took, with timestamps · every snapshot taken, with its
layer and cost · every health signal · the revert decisions and who made them · the cost figure at
teardown. Structured, append-only, one file or stream per rollout. The trace is the rollout's
memory after the rollout is gone.

## Hop 2 — retention as a stated rule

Everything is kept for a short window; after it, what survives is decided by a rule written down
per class — *reverted rollouts keep everything, completed rollouts keep actions and signals, the
raw resource profile is summarised*. The rule is the deliverable. Retention decided by disk
pressure is a rule too, and the worst one.

## Hop 3 — finding one failure across hundreds

Index the trace by the things a person searches for when something went wrong: the tool called,
the file touched, the signal raised, the snapshot layer, the declared Known-Good. Time is the
worst key, because the failure that matters happened at an unknown hour of a two-day rollout.

## Hop 4 — replay from a snapshot

A trace with its snapshots is a reproducible rollout: restore the snapshot before the point of
interest, replay the actions after it, and watch. This is phase 2's branch used for reading
instead of writing, and it is the reason snapshots are kept with the trace rather than beside it.

## How the phase fails

- Traces kept by time, so the failure at hour thirty of a two-day rollout is unfindable.
- Retention by disk pressure, so the rollouts that were reverted — the interesting ones — are the
  first to go, being the largest.
- Snapshots stored separately from traces, so replay needs a join nobody wrote.

## Verification

| | Command / observation | Expect |
|---|---|---|
| 1 | one rollout, one trace | every field above present; append-only; identity matches the rollout's |
| 2 | the retention rule per class | written before the first rollout of the class; applied as written |
| 3 | find the rollout that touched file X and raised signal Y | seconds, not a scan |
| 4 | replay from the snapshot before signal Y | the same actions reproduce the signal |

## Acceptance

One failure, described only by what happened inside it, found among hundreds of multi-day
rollouts and replayed from its own snapshot.

## Escape Hatch

If indexing cannot be built for a class, keep everything for that class and accept the disk
bill. A trace that cannot be searched is still a trace; a trace that was dropped is nothing.
