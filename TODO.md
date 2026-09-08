# What gets written next, and why in that order

Depth first, not breadth. One phase filled completely is worth more than one section filled
everywhere, because the thing a reader cannot judge yet is *what a finished section looks like
here*. Markers in a table are a promise; a worked section is the evidence.

## 1. ✅ Phases 1, 2 and 5 — the runs — **written 2026-09**

Why first: they are the two claims this repository exists to stand behind — isolation by hand up
to a user-space kernel, and a process checkpointed once and restored twice — plus the phase that
closes the loop from a definition to a rollout with a model to talk to. All three ran on the
minimum lab tier; the scripts that ran are in [`lab/`](lab/), byte for byte.

- [x] Phase 1 — namespaces and cgroups by hand · OCI runtime · gVisor on the systrap platform ·
      the same workload under each, with startup and throughput measured
- [x] Phase 2 — a filesystem snapshot and clone · a process checkpoint · two restores that diverge ·
      what CRIU refuses, and the flag that overrides it
- [x] Phase 5 — a definition validated, built to a digest, run under the tier it named, a model
      answering from inside the sandbox

## 2. Inheriting a platform

The page for someone who did not build the chain and has to run it: which verification rows to
run first, in what order, and what each one rules out. It reorders rows that already exist, which
is why it is cheap, and it is the page that makes this a playbook rather than a description.

## 3. Phases 3, 4, 6 — specifications

Scheduling and cost; failure, revert, continue; observability. Written as specifications with the
lab tier that could verify each named. They stay 🧭 until a tier exists that can run them, and the
repository says so rather than filling them with unrun code.

## 4. The mid lab tier

A machine with KVM would move Firecracker from ⛔ to 🔨 lab and VM snapshot from 🧭 to 🔨 lab. Not
bought for the marker; recorded so the next reader knows exactly what one machine would change.
