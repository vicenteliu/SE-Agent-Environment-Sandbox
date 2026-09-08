# Lab tiers

A tier is a named environment with an explicit list of what it can verify **and what it cannot**.
The second list is the payload.

| Tier | What it is | Verifies | Cannot verify |
|---|---|---|---|
| **minimum** — *the one the runs in this repository used* | one Linux virtual machine on an Apple-silicon workstation (4 vCPU, 8 GB, Ubuntu 24.04, kernel 6.8, cgroup v2), no nested virtualisation | namespaces and cgroups by hand · OCI runtime · gVisor on the **systrap** platform · CRIU checkpoint and restore · ZFS snapshot and clone · OCI packaging · a small model served on CPU | **Firecracker** and any KVM-platform runtime · VM snapshot and restore · accelerator state · anything multi-node · any number that would survive contact with production |
| **mid** | one x86 Linux machine with `/dev/kvm` | everything above, plus Firecracker microVMs, gVisor on the KVM platform, VM snapshot and restore | accelerator state (needs a CUDA device) · multi-node |
| **full** | two or more hosts with CUDA GPUs and a network between them | everything, including accelerator state in a snapshot and a scheduler running real rollouts across nodes | — |

## Why the minimum tier is a VM on a laptop-class machine

Because it is what exists, and because the two claims this repository stands behind — isolation
by hand up to a user-space kernel, and checkpoint-restore-branch — are verifiable there. A
specification page that says *"run this on a cluster"* verifies nothing; a runbook that says *"on
this 4-vCPU VM the syscall-heavy workload lost X% under gVisor and Y% under runc"* verifies one
thing, and says the tier.

## What one machine would change

A machine with KVM moves two hops: Firecracker from ⛔ to 🔨 lab, and VM snapshot from 🧭 to
🔨 lab. Recorded here so the reader knows the price of each marker, and recorded in
[TODO.md](../TODO.md) as *not bought for the marker*.
