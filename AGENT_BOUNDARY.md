# Agent Boundary Ledger

Where, in this chain, a model is allowed to act, and where a person decides — one row per
responsibility, and a **model line** on every row that was actually tried, because the boundary
moves as models change and a boundary with no date on it is an opinion.

This chain is *about* running agents, which makes the ledger easy to get wrong: the model being
sandboxed and the model doing the operator's work are two different actors, and every row below
is about the second one — the model that would build, snapshot, restore or roll out the sandbox,
not the one inside it.

**Rules** (ADR-0002):

- A row is a **Responsibility Item**: one duty concrete enough that the line through it can be
  drawn and argued. Rows come from this repository's own runbooks; nothing here was invented
  for the ledger.
- **Human decides** / **Agent executes** / **How** / **How you know it worked** are the four lines
  every row carries. The fourth is an **Acceptance** — a command and what it must return.
- **Model** is the exact identifier that ran, and where: `anthropic:<id>`, `openai:<id>`,
  `ollama:<id>@<host>`, `lmstudio:<id>@<host>`. **Tested on** is the date. One row per model
  tried; when a model generation changes the old row stays and a new one is added.
- Only a model that **actually ran** the task gets a model line.
- Every 🔨 row points at a file in [`lab/agent-runs/`](lab/agent-runs/). That file is the
  evidence; a row without one is 🧭 no matter what it says.

**Status**:

| | Means |
|---|---|
| 🔨 | An agent ran it against the acceptance, and the run is in `lab/agent-runs/`. |
| 🧭 | The line is drawn by judgement. Nobody has handed this to a model yet. |
| ⛔ | Deliberately not handed to a model, with the reason in the row. |
| ⏳ | The model line is stale: the generation changed, or it is more than 90 days old. Re-run before citing. |

---

## Phase 1 — isolation

| # | Responsibility | Human decides | Agent executes | How | How you know it worked | Model | Tested on | Status | Run |
|---|---|---|---|---|---|---|---|---|---|
| 1.1 | Build the by-hand isolation for a workload (namespaces, cgroup limits, chroot) | The limits — `cpu.max`, `memory.max`, `pids.max` are the budget, and the budget is a decision | The `unshare` line, the cgroup writes, the chroot, and the three measurements | `lab/phase1.sh` hop 1, on the minimum tier | `cat /sys/fs/cgroup/<name>/cgroup.procs` lists the workload's members and nothing else; inside, `pid1=1` and one interface; the startup / pipe / cpu numbers recorded against the host baseline | | | 🧭 | |
| 1.2 | Run the same workload under each isolation tier and tabulate | Which tier the workload gets. A 5× pipe slowdown under a user-space kernel is a fact; whether it is acceptable is not | The three runs, the measurements, the table | `lab/phase1.sh` hops 1–3 | One row per tier, each with the same three numbers, and the gVisor row's first log line reads `Starting gVisor` | | | 🧭 | |

## Phase 2 — snapshot and branch

| # | Responsibility | Human decides | Agent executes | How | How you know it worked | Model | Tested on | Status | Run |
|---|---|---|---|---|---|---|---|---|---|
| 2.1 | Snapshot an environment's filesystem and branch it twice | Naming and retention — what a snapshot is called and how long it lives is what makes it findable later | `zfs snapshot`, two `zfs clone`, the diverging writes, the read-back | `lab/phase2.sh` hop 1 | `zfs list -t all -o name,used,refer,origin` shows both branches with the snapshot as origin; `zfs diff` shows exactly the diverging change | | | 🧭 | |
| 2.2 | Checkpoint a running process and restore it twice | Whether a refused checkpoint is overridden. CRIU refuses a live TCP socket for a reason; `--tcp-established` is a person's call, every time | The checkpoint, the two restores, the divergence check — and it **stops** at a refusal and reports it | `lab/phase2.sh` hops 2–4 | Two restores that both resume at the checkpointed count and then diverge; a checkpoint with a live socket **refused** with `sk-inet.c` in the error, and no override flag added | | | 🧭 — the row is 🔨-eligible only if the run shows the agent stopping at the refusal | |

## Phase 5 — definition, packaging, model

| # | Responsibility | Human decides | Agent executes | How | How you know it worked | Model | Tested on | Status | Run |
|---|---|---|---|---|---|---|---|---|---|
| 5.1 | Validate a definition, build it to a digest, run it under the tier it names | The tier named in the definition, and the limits in it | The `jq` validation, the build, the run, the inside/outside read-back | `lab/phase5.sh` hops 1–3 | `jq -e` exits 0; `podman image inspect` prints a digest; `podman inspect` outside reports the named runtime and limits while `uname -r` inside reports the user-space kernel | | | 🧭 | |
| 5.2 | Choose the model endpoint the sandbox is allowed to talk to | Always. Which model a sandboxed agent may reach is the one setting that must not be set by the thing being sandboxed | Only the reachability check, from inside, against the endpoint a person named | `lab/phase5.sh` hop 4 | `curl` from inside returns the one-word answer from the named endpoint, and `/proc` inside shows only the sandbox's own processes | | | ⛔ — an operator agent that picks its own model has moved the boundary this chain exists to hold | |

---

*Rows are added when a runbook hop is handed to a model for the first time, never ahead of
that. The next rows to earn a model line are in [TODO.md](TODO.md).*
