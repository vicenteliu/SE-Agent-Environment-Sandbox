# Choosing an isolation tier

The role that prompted this repository named four ways to separate a rollout from its host —
namespaces and cgroups, virtual machines, and two sandboxing runtimes by name. That is a selection
problem, so this is a selection document: the criteria, then where each tier sits, then the rule
for assigning a tier to an environment class. The runs behind the measured columns are in
[phase 1](../phases/1-isolation/).

## Criteria

| Criterion | Question it answers |
|---|---|
| **Boundary** | If the agent inside is hostile or broken, what does it reach? |
| **Fidelity** | Does the environment behave like the real system the agent is being trained for? |
| **Startup** | How long from *start* to *first instruction*, cold and warm? |
| **Overhead** | What does a syscall-heavy workload lose to the boundary? |
| **Snapshot layer** | Which of the four snapshot layers does this tier make cheap? |
| **Accelerator** | Can a GPU be reached, and what does that do to the boundary? |
| **Host requirement** | What must the host have — a kernel feature, KVM, a specific device? |

## The four tiers

| Tier | Boundary | Fidelity | Startup | Overhead | Snapshot layer it makes cheap | Accelerator | Host requirement |
|---|---|---|---|---|---|---|---|
| **Namespaces + cgroups by hand** | the host kernel; every syscall is real | highest — it *is* the host | lowest | none beyond the limits | filesystem (overlay / ZFS) | direct device access | any Linux kernel with cgroup v2 |
| **OCI runtime** (runc / crun) | same kernel, packaged and policed (seccomp, caps, rootless) | same | low | measured in phase 1 | filesystem; process via CRIU | device passthrough by config | same |
| **User-space kernel** (gVisor) | a second kernel in user space; the host kernel sees one process | reduced — it implements Linux, it is not Linux | low, higher than runc | measured in phase 1; the price is the whole point | filesystem; process checkpoint is the runtime's own | limited, evolving | any kernel; **systrap** platform needs nothing, **KVM** platform needs `/dev/kvm` |
| **microVM** (Firecracker-class) | a hardware virtual machine; the host kernel is not shared | high — a real guest kernel | higher; warm pools exist for this reason | low once running | **VM snapshot** — the layer that captures memory *and* device state together | passthrough only, with the boundary cost that implies | **KVM** — the tier this lab cannot run (⛔) |

## The assignment rule

Assign a tier per **environment class**, not per rollout, and write the assignment down where the
environment spec lives. The rule that survives contact with cost:

1. **Start from the boundary the class needs**, not the fidelity it would like. An environment
   that executes untrusted code an agent wrote starts at gVisor or a microVM; an environment that
   only calls sanctioned tools may stop at the OCI runtime.
2. **Then buy back fidelity only where the training signal needs it.** If the agent is learning a
   real system's behaviour, a user-space kernel's divergences become training noise; that is the
   argument for the microVM, and it is a per-class argument.
3. **Then measure, on the tier chosen, the two numbers that set cost-per-rollout** — startup and
   overhead — because the ranking above is qualitative and the lab numbers in phase 1 are for one
   workload on one machine.

## What this document does not decide

Which tier *a given organisation* runs. That depends on the threat model, the hardware, and the
training signal — three things a public document cannot know. It decides the criteria and the
order in which to apply them.
