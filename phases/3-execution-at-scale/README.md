# Phase 3 — Execution at scale

> One rollout that works, to thousands that are affordable.

🧭 **Specified, not run.** Nothing in this repository has scheduled more than one rollout at a time,
and the page says so. The [full lab tier](../../docs/02-lab-tiers.md) is what would verify it.

| # | Hop | Marker | What it answers |
|---|---|---|---|
| 1 | **Cost-per-rollout as the objective** | 🧭 | What a rollout costs, in what units, and which of those units are not for sale |
| 2 | **Warm pools and startup** | 🧭 | Why the first instruction is late, and which tier's startup is the bottleneck |
| 3 | **Scheduling and preemption** | 🧭 | Who runs when the cluster is full, and whose rollout loses |
| 4 | **Teardown as part of cost** | 🧭 | Why a rollout is not finished when the agent stops |

## Prerequisites

- Phases 1 and 2 accepted: a tier assignment per environment class, and a snapshot layer per tier.
- A host inventory with per-host capacity in the same units the objective uses.
- An owner for the priority policy. Not a metric — a person.

## Hop 1 — cost-per-rollout as the objective

A rollout's cost is **wall-clock on the tier × the tier's hourly cost, plus the snapshots it took,
plus its teardown**. The objective is *more rollouts per unit of that*, subject to two constraints
that are not traded: a rollout is never silently killed without a snapshot, and a Known-Good is
never overwritten. Everything the scheduler is allowed to do is a move inside those constraints.

⚠️ The trap is optimising the visible number — throughput — and paying in the invisible one,
which is rollouts that finished but cannot be trusted. Reliability is the constraint, not a term
in the objective.

## Hop 2 — warm pools and startup

Phase 1 measures cold startup per tier. At scale the cold number is paid once per pool member, not
once per rollout: a pool of pre-started, snapshotted-at-ready environments turns startup into a
restore, which phase 2 has already priced. The pool size is a cost decision — idle members cost
money, empty pools cost latency — and it is per environment class, like the tier.

## Hop 3 — scheduling and preemption

Bin-pack by the tier's dominant resource (memory for microVMs, CPU for user-space kernels,
accelerator for anything that has one). Preempt only through phase 2's snapshot: a preempted
rollout is a snapshot plus a place in the queue, never a loss. **Whose rollout loses when the
cluster is full is a policy a person owns**; the scheduler executes it and reports what it did.

## Hop 4 — teardown as part of cost

A rollout that has stopped still holds a filesystem, a process tree, possibly a device. Teardown
time is measured and charged to the rollout, because on a shared host it is the next rollout's
startup latency in disguise.

## How the phase fails

- Throughput rises and confidence falls — rollouts that completed under preemption pressure with
  a snapshot missing.
- A warm pool for a class nobody runs any more, paid for monthly.
- A priority policy that exists only in the scheduler's configuration, so nobody can say who
  decided it.

## Verification

| | Command / observation | Expect |
|---|---|---|
| 1 | a cost figure emitted per rollout at teardown | units match the objective; snapshots and teardown included |
| 2 | first-instruction latency, cold vs from-pool, per tier | pool latency ≈ phase 2's restore time for that tier |
| 3 | fill the cluster past capacity | the lowest-priority rollout is snapshotted, not killed; the policy owner's name is in the log line |
| 4 | teardown time per rollout | present in the cost figure; outliers explainable |

🧭 None of these rows has a command that the minimum tier can run. They are the acceptance a
reader with the full tier should hold this phase to.

## Acceptance

Ten thousand rollouts scheduled across the full tier, every preemption traceable to a snapshot,
and the cost figure per rollout within a stated tolerance of the hardware bill.

## Escape Hatch

If preemption-by-snapshot is too slow for a tier, that tier gets no preemption: rollouts on it
run to completion and the class's queue is sized accordingly. Slower and honest beats fast and
lossy.
