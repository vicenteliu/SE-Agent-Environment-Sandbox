# Phase 2 — Snapshot, restore, branch

> A rollout that can be paused, copied, and sent down two roads.

🔨 lab **Run on the minimum tier** for the filesystem and process layers. 🧭 The VM layer is
specified for the mid tier. ⛔ The accelerator layer is specified, not run, and the reason is
that this tier has no CUDA device.

| # | Hop | Marker | What it answers |
|---|---|---|---|
| 1 | **Filesystem snapshot and clone** (ZFS) | 🔨 lab | What a branch costs on disk, and how fast a restore is |
| 2 | **Process checkpoint** (CRIU, through the runtime) | 🔨 lab | Freezing a running process tree to a file |
| 3 | **Two restores from one checkpoint** | 🔨 lab | The branch: one past, two futures |
| 4 | **What CRIU refuses** | 🔨 lab | The boundary of the process layer, demonstrated |
| 5 | **VM snapshot** | 🧭 | Memory and device state together — the microVM tier's reason to exist |
| 6 | **Accelerator state** | ⛔ | The layer nothing above captures |

## Prerequisites

- Phase 1 accepted: a rootfs, an image, a runtime, and a container engine that can drive CRIU
  (`podman` with **`runc`** — see *How the phase fails* for why that word is bold).
- ZFS available to the kernel (`modprobe zfs`), and a pool. The lab's pool is a 4 GB file-backed
  vdev; that is enough to show the accounting and nothing else.
- CRIU installed and its version printed. The engine's checkpoint command calls it.

## Hop 1 — filesystem snapshot and clone

A dataset holds the rollout's state. `zfs snapshot` is instant and free; `zfs clone` from the
snapshot produces a writable branch that **shares every block with the snapshot until it is
written**. The accounting is the point: after both branches diverge, `zfs list` shows each
branch's `USED` as *only what it wrote* — kilobytes for a branch that changed one line,
megabytes for a branch that wrote a new file — while the origin snapshot carries the shared base
once. A third clone from the same snapshot, taken after the others have diverged, is a restore,
and it takes milliseconds because nothing is copied.

🔑 **The snapshot lands in the storage layer, not the container or the hypervisor.** That is why
it costs nothing to take and why it survives whatever happens to the process above it — and why
it captures nothing about the process at all.

## Hop 2 — process checkpoint

A container that counts once a second into a file. `podman container checkpoint --export` freezes
the process tree, dumps memory, file descriptors and namespaces to an archive, and stops the
container. The count at checkpoint is the last number the process wrote.

## Hop 3 — two restores from one checkpoint

`podman container restore --import` twice, with two new names, seconds apart. Each restored
process resumes from the *same* count and keeps counting in its own container; read the two
files a few seconds later and they differ — one past, two futures. That is the branch, at the
process layer, and it is the primitive phase 4's revert-and-continue is built from.

## Hop 4 — what CRIU refuses

A container with an **established TCP connection** is checkpointed the same way. CRIU refuses by
default: a live socket is state on the other end of the wire, and restoring it somewhere else
would be a lie to the peer. The option to force it exists (`--tcp-established`) and is exactly the
kind of flag that should be a per-class decision, not a default. The same refusal applies to
anything the process holds that the kernel cannot serialise — device handles above all, which is
hop 6.

## Hop 5 — VM snapshot 🧭

On the mid tier, a microVM snapshot captures guest memory and device state together, in one
operation, without cooperation from the process. It is the only layer that makes *memory* and
*devices* one artifact — the reason the microVM tier exists in this chain — and it costs the most
per snapshot. Specified: Firecracker's snapshot API (pause, snapshot-full, restore into a new
microVM), verified by the same counter diverging across two restored guests.

## Hop 6 — accelerator state ⛔

Nothing above captures what is inside a GPU: allocations, streams, kernel state. Tooling exists
for one vendor's devices to checkpoint that state in cooperation with the driver; it needs the
device present and the driver's blessing, and this tier has neither. **Specified**: on the full
tier, a process holding a device allocation, checkpointed with the vendor tool in the loop,
restored, and the allocation's contents compared before and after. The reason it is last: it is
the only layer where the answer to *"can this be snapshotted at all"* depends on the hardware.

## How the phase fails

- **The engine's default runtime cannot checkpoint.** On this distribution `podman` defaults to
  `crun`, built without CRIU support; the checkpoint command fails with *configured runtime does
  not support checkpoint/restore*, and every restore fails after it with a missing archive. The
  first run of this page hit exactly that. The fix is `--runtime runc` on the container that will
  be checkpointed — a per-container choice, which means the runtime is part of the environment
  class's tier assignment, not an afterthought.
- **A socket the checkpoint never saw.** The first version of the refusal test opened the
  connection with `podman exec`. The checkpoint *succeeded* — and the exec session simply died.
  A process started through `exec` hangs off the engine's monitor, not off the container's
  init, so CRIU's dump of the init tree does not contain it. The test now opens the connection
  from the container's own command, and CRIU refuses as documented. The lesson generalises:
  *what a checkpoint contains is the process tree, not the container*, and anything that
  entered the container by another door is not in it.
- **Restoring twice without new identities.** Two restores of one archive with the same name,
  IP or MAC collide; the flags that ignore static addressing exist for this reason.
- **Trusting a filesystem snapshot to have captured a process.** It did not. A branch of the
  filesystem under a running process is a branch of the disk only.
- **Snapshotting the accelerator layer by snapshotting the VM.** The VM snapshot captures the
  guest's *view* of the device, not the device.

## Verification

One run on the minimum tier. A 4 GB file-backed pool; a 64 MB dataset; a shell counter as the
process.

| | Command | Result |
|---|---|---|
| 1 | `zfs snapshot labpool/env@t1` · `zfs clone` ×2 · write one line in a, one line + 16 MB in b · `zfs list -t all -o name,used,refer,origin` | `branch-a USED 12K` · `branch-b USED 16.0M` · both `ORIGIN labpool/env@t1` · snapshot `0B` — each branch pays only for what it wrote |
| 1 | `zfs diff labpool/env@t1 labpool/branch-b` | `M state.txt` · `+ extra` |
| 1 | a third `zfs clone` from the same snapshot after both branches diverged | **6 ms**, and its `state.txt` reads the pre-snapshot line |
| 2 | `podman --runtime runc container checkpoint counter -e counter.tar` at count 9 | **296 ms**, archive **36 KB**, container `exited`; CRIU 4.2.1 |
| 3 | `podman --runtime runc container restore -i counter.tar -n branch-a` · again as `branch-b` five seconds later | restore **120 ms** and **189 ms**; both resume at **9**; read again later: `branch-a 17`, `branch-b 12` |
| 4 | a container holding an established TCP connection, then `checkpoint` | **refused** — `Error (criu/sk-inet.c:200): inet: Connected TCP socket, consider using --tcp-established option.` · `Dumping FAILED.` · container still `running` |
| 4 | the same, with `--tcp-established` | **succeeds**, archive **240 KB** (vs 36 KB for the socket-less counter) — the socket state is in the image now, and the peer was not asked |
| 5 | *(mid tier)* Firecracker pause → snapshot-full → restore into a new microVM, the same counter | 🧭 not run |
| 6 | *(full tier)* a process with a device allocation, checkpointed with the vendor tool, restored, contents compared | ⛔ not run — no CUDA device on any tier the author has |

## Acceptance

One running process, checkpointed once and restored twice into containers whose counts have
diverged, on filesystems that were cloned from one snapshot and whose `USED` columns show only
what each branch wrote. Hops 5 and 6 have tiers named that can run them.

## Escape Hatch

If the process layer cannot be checkpointed for a class (device handles, live sockets that must
not be forced), that class snapshots at the filesystem layer only and *restarts* the process from
its last durable state — slower, and honest about what was kept.
