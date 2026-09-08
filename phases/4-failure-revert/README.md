# Phase 4 — Failure, revert, continue

> The loop that makes a long rollout survivable.

🧭 **Specified, not run.** The primitive it depends on — branch from a snapshot — is run in
[phase 2](../2-snapshot-branch/). The policy over it is specified here.

| # | Hop | Marker | What it answers |
|---|---|---|---|
| 1 | **Health signals** | 🧭 | What a rollout emits that can be judged without reading its mind |
| 2 | **Known-Good declaration** | 🧭 | Who says which snapshot is safe to return to — and why it is not the system |
| 3 | **Revert, patch, continue** | 🧭 | The mechanics of going back without starting over |
| 4 | **Reward hacks as infrastructure** | 🧭 | What the infrastructure can and cannot see of a misbehaving agent |

## Prerequisites

- Phase 2 accepted on the tier in question: a snapshot can be taken on schedule and restored twice.
- A person named as the declarer of Known-Good for each environment class.

## Hop 1 — health signals

Three families, in order of how much they can be trusted:

1. **Infrastructure faults** — the sandbox died, the filesystem filled, a device disappeared. Cheap,
   unambiguous, automatable end to end.
2. **Resource anomalies** — a rollout's CPU, memory, I/O or syscall profile leaves the envelope its
   class has shown before. Cheap, ambiguous: an anomaly is a question, not a verdict.
3. **Behavioural signals** — the agent's actions themselves: files touched outside the task, tools
   called in an order that makes no sense, a reward rising while the task visibly is not done.
   Expensive to define and never fully automatable; this is where reward hacks live.

## Hop 2 — Known-Good declaration

A **Known-Good** is a snapshot a person has declared safe to return to. The system proposes —
*"the last snapshot before signal X"* — and a person confirms or picks another. The reason this is
not automated is not caution for its own sake: a system that decides which of its own states was
good is grading its own homework, and a reward hack is precisely the case where the system's
opinion is the thing that cannot be trusted.

## Hop 3 — revert, patch, continue

Revert is phase 2's branch: restore the Known-Good into a fresh rollout identity, leaving the
failed history intact for phase 6 to keep. Patch is whatever changes the environment or the task
so the failure does not recur — a tool removed, a limit tightened, a task clarified — and it is
applied to the *class*, not the one rollout, or the next rollout hits it again. Continue is a
new rollout from the branch, with the patch, with the old trace linked.

## Hop 4 — reward hacks as infrastructure

The infrastructure sees actions and resources, not intent. What it can do: keep every action,
make every state restorable, and make the envelope of *normal* for a class measurable. What it
cannot do: decide that a rising reward is a hack. That decision is a person's, made against the
trace phase 6 kept, and the infrastructure's job is to make that decision possible in minutes
rather than impossible.

## How the phase fails

- Auto-revert on resource anomalies: a legitimately hard task looks anomalous, gets reverted in a
  loop, and never finishes.
- Known-Good inferred by the system: the last snapshot before the crash was already compromised.
- Patching the rollout instead of the class.

## Verification

| | Command / observation | Expect |
|---|---|---|
| 1 | inject an infrastructure fault mid-rollout | signal within seconds; the proposed revert point is the last snapshot before the fault |
| 2 | the declaration log | every revert names a person and a snapshot |
| 3 | revert → patch → continue | new rollout identity; old trace linked; the patch present in the class spec |
| 4 | replay a known misbehaving trace | every action visible; the anomaly envelope flags it; no automatic verdict |

🧭 Row 1 could run on the minimum tier with phase 2's tooling; it has not, and the marker says so.

## Acceptance

A rollout that failed at hour six is continued from a person-declared Known-Good with a patch
applied to its class, and the failed six hours are still readable.

## Escape Hatch

If Known-Good declaration cannot be staffed for a class, that class does not auto-revert at all:
it stops on signal and waits. Waiting is a cost; a wrong revert is a lie in the training data.
