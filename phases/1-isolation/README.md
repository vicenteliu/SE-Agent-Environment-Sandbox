# Phase 1 — Isolation tiers

> The same workload under four boundaries, and what each boundary costs.

🔨 lab **Run on the minimum tier** — one 4-vCPU Ubuntu 24.04 VM (kernel 6.8, cgroup v2), one
workload generator, ten startup samples per tier, fifteen-second timed runs. ⛔ **The microVM tier
was not run** and the reason is on the page: no KVM on this tier. Every number below is for
*this* workload on *this* machine; the ranking is the durable part, the digits are not.

| # | Hop | Marker | What it answers |
|---|---|---|---|
| 0 | **No isolation** (the baseline) | 🔨 lab | What the machine does with nothing in the way |
| 1 | **Namespaces and cgroups by hand** | 🔨 lab | What a container *is* before a runtime hides it — and what a runtime does for you |
| 2 | **OCI runtime** (runc) | 🔨 lab | The packaged form of hop 1: same kernel, policed |
| 3 | **User-space kernel** (gVisor, systrap) | 🔨 lab | A second kernel between the workload and the host, and its price |
| 4 | **microVM** (Firecracker) | ⛔ | A separate kernel entirely — specified, not run |

## Prerequisites

- A Linux host or VM with cgroup v2 mounted and the `cpu`, `memory` and `pids` controllers
  available at the root (`cat /sys/fs/cgroup/cgroup.controllers`).
- An OCI runtime (`runc`), a container engine to build and export with (`podman`), and the gVisor
  runtime binary (`runsc`), checksum-verified against the release manifest.
- One image containing the workload generator and nothing else — the lab's `Containerfile` is
  three lines. Its rootfs, exported to a directory, is what hops 1 and 2 run on; the image itself
  is what hop 3 runs.
- `stress-ng` as the workload: one **pipe** stressor (a tight loop of `write`/`read` on a pipe —
  every iteration is two syscalls and a copy) and one CPU-bound stressor, each timed for fifteen
  seconds. The first is the one that shows a boundary; the second is the control that should not.
  ⚠️ Not the `--syscall` stressor — see *How the phase fails* for why.

## Hop 0 — the baseline

`/bin/true` from a shell, ten times, for startup; the two stressors directly on the VM for
throughput. This is the denominator for everything else. On a VM it is already one boundary
removed from hardware, which is why the page never claims a number for bare metal.

## Hop 1 — namespaces and cgroups by hand

`unshare --mount --uts --ipc --net --pid --fork --cgroup`, a cgroup directory with `cpu.max`,
`memory.max` and `pids.max` written into it, the process's PID written to `cgroup.procs`, then
`chroot` into the exported rootfs. No runtime, no engine.

🔑 **What this hop teaches is what a runtime does for you, by making you do it.** The exported
rootfs has an **empty `/dev`**, no `/proc`, no `/sys`. The first run of the workload under
this tier produced no output at all — the stressor could not open `/dev/null`. The fix is five
`mount` and `mknod` lines that every runtime executes silently on every container start. The
hostname must be set by hand inside the new UTS namespace or the container reports the host's.
The new network namespace has one interface, `lo`, and it is down.

⚠️ This tier's boundary is the **host kernel with a narrower view**. Every syscall is the real
one. A process here that finds a kernel bug is on the host.

## Hop 2 — OCI runtime

`runc spec` generates the bundle configuration; the same rootfs, the same three limits written
into `linux.resources`, `runc run`. What the runtime adds over hop 1 and that hop 1 did not do:
the `/dev` population, the seccomp profile, the capability drop, the mount propagation, the
`/proc` masking. The boundary is the same kernel; the surface exposed to the process is smaller.

## Hop 3 — user-space kernel

`podman run --runtime runsc` on the same image. gVisor's first line inside the container is its
own kernel banner — *Starting gVisor…* — because the process is talking to a kernel written in
user space that reimplements the Linux syscall surface and makes a much smaller set of calls to
the real one. On this tier gVisor runs on its **systrap** platform, which needs no hardware
virtualisation; the **KVM** platform is faster and is what the mid tier would use.

🔑 **The price is visible in exactly the workload that should show it.** The CPU-bound stressor
loses almost nothing; the pipe stressor pays for every crossing. Startup pays most of all —
a whole kernel is being started — and that number is why phase 3 talks about warm pools.

## Hop 4 — microVM ⛔

A Firecracker microVM boots a real guest kernel in a hardware VM; the host kernel is not shared
at all. It needs `/dev/kvm`. The minimum tier is a VM on Apple silicon without nested
virtualisation, so `/dev/kvm` does not exist there and the hop cannot be run. **Specified**: on
the mid tier, `firecracker --api-sock` with a kernel image and a rootfs block device, the same
three limits as machine config, the same two stressors inside the guest, and one extra row —
snapshot-restore of the whole VM, which is the reason this tier exists in phase 2.

## How the phase fails

- **Measuring startup with a warm cache and calling it cold.** Ten samples, and the first is
  discarded in your head but not in the mean. The numbers here are means of ten with nothing
  discarded, which overstates nothing.
- **Comparing a tier with limits to a tier without.** Hop 0 has no cgroup; hops 1–3 have the same
  three limits. The CPU stressor runs one worker, so `cpu.max` at two CPUs never binds — the
  control is a control.
- **A benchmark that chooses its own tests.** The first version of this page used the
  `--syscall` stressor. Under the OCI runtime it reported *four orders of magnitude* more
  operations per second than on the host — and *failed: 0*. It was not faster: the stressor
  calibrates by exercising only the *"fastest non-failing"* subset of nearly three hundred syscall
  tests, and inside a container a different subset qualifies. It measured its own selection. The
  page now uses the pipe stressor, which does the same two syscalls every iteration on every tier,
  and the numbers are ratios between tiers on one machine, nothing more.
- **Believing the rootfs is a container.** Hop 1's empty `/dev` is the proof that it is not.

## Verification

Per hop, the command and what it produced on the minimum tier (one run, 2026-09; ten startup
samples, fifteen-second stressors, one worker each; the pipe stressor is `write`/`read` on a pipe).

| | Command | Result |
|---|---|---|
| 0 | `/bin/true` ×10 · `stress-ng --pipe 1 -t 15s` · `stress-ng --cpu 1 -t 15s` | startup **0.64 ms** · pipe **1,430,840 ops/s** · cpu **378.2 ops/s** |
| 1 | `unshare --mount --uts --ipc --net --pid --fork --cgroup` + cgroup v2 limits + `chroot` | startup **9.9 ms** · pipe **1,351,846** (95% of host) · cpu **375.4** |
| 1 | `cat /sys/fs/cgroup/lab-t1/cgroup.procs` while the workload runs | **3 members**; `memory.current` ≈ 0.9 MB; `cpu.max` 200000/100000, `memory.max` 512 MiB, `pids.max` 256 |
| 1 | inside: `echo pid1=$$ hostname=$(hostname) ifaces=$(ls /sys/class/net)` | `pid1=1 hostname=lab-t1 ifaces=lo procs=4` — its own PID space, its own name, one interface |
| 2 | `runc spec` + three limits in `linux.resources` + `runc run` | startup **20.0 ms** · pipe **1,354,073** (95%) · cpu **378.0** |
| 3 | `podman run --runtime runsc` (systrap) | first line `[    0.000000] Starting gVisor...` · startup **244.6 ms** · pipe **282,084** (**20%** of host, 5.1× slower) · cpu **369.6** (−2%) |
| 4 | `ls /dev/kvm` | *No such file or directory* — ⛔ not run on this tier |

Read across, not down: the pipe column is the boundary's price, the cpu column is the control
that barely moves, and the startup column is what phase 3's warm pools exist to hide. Hop 1's
startup includes the five mounts and device nodes done by hand; hop 2's includes everything a
runtime does that hop 1 skipped.

## Acceptance

The same workload has run under hops 0–3 on one machine, the syscall-heavy stressor shows the
boundary's cost in the order *host ≈ by-hand ≈ runtime < user-space kernel*, the CPU-bound
stressor shows no such order, and startup shows the reverse order with the user-space kernel
last by more than an order of magnitude. Hop 4 has a tier named that can run it.

## Escape Hatch

If `runsc` will not start on a tier (no `/dev/kvm` **and** no `ptrace`/`systrap` support in the
kernel), the user-space-kernel hop degrades to ⛔ with the kernel version recorded, and the
selection document's rule still holds: the environment class that needed that boundary waits
for a tier that has it rather than running on a thinner one.
