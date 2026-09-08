# The chain, hop by hop

What each hop takes in, what it hands to the next, and what the next one assumes of it. The
phase pages carry the commands; this page carries the contract between them.

| # | Hop | Phase | In | Out | The next hop assumes |
|---|---|---|---|---|---|
| 1 | **Environment definition** | 5 | a declarative description: base image, tools the agent may call, the model endpoint, resource limits, what counts as done | a validated spec | the spec is complete enough to build without asking a human |
| 2 | **Image** | 5 | the spec | an OCI image, content-addressed | the image is immutable and its digest is the rollout's identity |
| 3 | **Isolation tier** | 1 | the image, a tier choice | a running container / user-space kernel / microVM with limits applied | the boundary chosen is the one the environment class was assigned, not the default |
| 4 | **Running rollout** | 1 → 3 | the isolated process tree, the agent's actions | a rollout with a stable identity across pauses | its filesystem, process state and (where present) accelerator state are addressable separately |
| 5 | **Snapshot** | 2 | a running rollout, a layer choice (fs / process / vm / accelerator) | a captured state with a name and a cost | the snapshot is restorable on the same tier, and the page says what it does *not* capture |
| 6 | **Branch / restore** | 2 | a snapshot | one or more restored rollouts that diverge | two restores of one snapshot do not share mutable state |
| 7 | **Health signal → revert or continue** | 4 | rollout signals, a **Known-Good** declaration | a decision: continue, or revert to Known-Good and patch | the revert point was declared by a person, not inferred |
| 8 | **Teardown** | 3 | a finished or abandoned rollout | reclaimed resources, a cost figure for the rollout | teardown time is measured, because it is part of cost-per-rollout |
| 9 | **Trace kept** | 6 | everything the rollout emitted | the subset retained, indexed by rollout identity | what was dropped was dropped by a stated retention rule |

## The two loops through the chain

**The rollout loop** — hops 3 → 4 → 5 → 6 → 7 → 4 … — is what a long-horizon environment is:
run, snapshot, keep going, and when a signal says stop, branch from the last Known-Good rather
than start again. Phase 2 is the primitive; phase 4 is the policy.

**The scale loop** — hops 3 → 4 → 8, thousands of times — is where cost-per-rollout lives. Phase 3
specifies it; nothing in this repository runs it, and the lab tiers page says what would.

## What is deliberately not a hop

- **Reward computation and training.** They consume rollouts; they are not part of running one.
- **Cloud provisioning.** The chain starts at an image on a host that exists.
- **The agent itself.** Whatever acts inside the environment is a black box to this chain, by
  design — the boundary is the point.
