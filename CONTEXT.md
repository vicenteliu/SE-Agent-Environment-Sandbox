# Context

The words this repository uses, and what each means here. A glossary and nothing else.

## Language

**Playbook**:
The whole of this repository — the **Chain**, one **Runbook** per phase, and the decisions in
between — written first for a reader with five minutes, then for the author on the job, where
it is the frame a platform is run from and instantiated per environment. Never a case study.
_Avoid_: "method repository," "portfolio," "reference implementation," "showcase"

**Chain**:
The ordered sequence of **Hops** from an environment definition to a kept trace. The chain is the
spine; every hop states what the next one assumes of it.
_Avoid_: "pipeline" (that word is used for packaging only), "workflow"

**Hop**:
One step of the chain with a definable input, output and marker. A hop is 🔨, 🔨 lab, 🧭 or ⛔;
never unmarked.
_Avoid_: "task," "step," "stage"

**Runbook**:
One phase, in six sections: prerequisites · hops · how the phase fails · verification · acceptance ·
escape hatch. The phase is the boundary of acceptance — one outcome proves several hops.
_Avoid_: "guide," "procedure," "SOP," "phase README"

**Rollout**:
One execution of an environment by an agent, from start to teardown. The unit everything here is
costed, snapshotted and traced against.
_Avoid_: "run" (ambiguous with a lab run), "episode," "job"

**Isolation Tier**:
One of the four ways a rollout is separated from the host and from other rollouts — namespaces and
cgroups by hand, an OCI runtime, a user-space kernel (gVisor), a microVM. Tiers trade fidelity and
cost against the strength of the boundary; the selection between them is a document, not a default.
_Avoid_: "sandbox level," "security level"

**Snapshot**:
A captured state of a rollout at one layer — filesystem, process, virtual machine, or accelerator.
Each layer costs differently and captures different things; a snapshot at one layer is not a
snapshot at the others.
_Avoid_: "backup," "checkpoint" (reserved for the process layer specifically), "image"

**Branch**:
Two or more restores of the same snapshot that then diverge. The primitive that turns a rollout
from one-shot into something that can be inspected and retried.
_Avoid_: "fork" (a process term), "clone" (a filesystem term — a clone is how a branch is made at
that layer, not the branch itself)

**Known-Good**:
The most recent state of a rollout a human has declared acceptable to revert to. A declaration, not
a measurement — the health signals propose, a person declares.
_Avoid_: "last good," "stable," "baseline"

**Lab Tier**:
A named hardware and software environment with an explicit list of which **Hops** it can verify
*and which it cannot*. The boundary is the payload: a tier whose limits are not stated verifies
nothing.
_Avoid_: "environment," "setup," "tier" (unqualified)

**Specced-Not-Run** (⛔):
A hop with a complete environment specification, verification steps and acceptance criteria that
was deliberately not executed, with the reason stated. Not a missing 🧭: a 🧭 has no plan, this
has one.
_Avoid_: "planned," "not done," "TODO," "future work"

**Acceptance**:
The one outcome that proves a phase, stated as something observable. Per phase, never per hop.
_Avoid_: "definition of done," "success criteria"

**Escape Hatch**:
What to do when the phase's acceptance cannot be reached on the tier at hand — the honest fallback,
written before it is needed.
_Avoid_: "workaround," "plan B"

**Responsibility Item**:
One duty from the chain, concrete enough that the line between what a person decides and what
a model executes can be drawn through it and argued — a row in the **Agent Boundary Ledger**.
Taken from a **Runbook** hop, never invented for the ledger. In this chain the duty belongs to
the *operator's* agent, not to the agent being sandboxed; the ledger's first paragraph says so.
_Avoid_: "task," "duty," "use case," "job"

**Agent Boundary Ledger** (`AGENT_BOUNDARY.md`):
One row per **Responsibility Item**, four lines each — *Human decides / Agent executes / How /
How you know it worked* — and a **model line**: the exact model identifier, where it ran, the
date. A row is 🔨 only when an **Agent Run** stands behind it; a model that did not run the
task has no line; when a model generation changes the old line stays and a new one is added,
because the ledger's payload is the boundary *moving*. A model line older than 90 days, or from
a superseded generation, is ⏳ until re-run (ADR-0002).
_Avoid_: "AI policy," "automation matrix," "capability map," "what AI can do"

**Agent Run**:
One file in `lab/agent-runs/` — the command, the model as the endpoint reported it, the task
and acceptance verbatim, the complete transcript, and the pass/fail against the acceptance.
Made through an agent CLI when the responsibility needs tools, through the bare API when it
does not, and the file says which. It is the credential behind a ledger row, screened for
secrets before it is committed.
_Avoid_: "experiment," "eval," "benchmark," "demo"

**Verification row** (rule, ADR-0002):
A command and what it must return. Every row in the phases that ran already is one; the rule is
recorded so it binds what is written next. Sections written after 2026-09-15 open with *Before
you start · Permissions · Minimum test · Verify · Rollback*.
_Avoid_: "manual check," "eyeball," "confirm in the UI"
