# A verification row is a command, and the agent boundary is a ledger with a date on every model

The same decision as `SE-macOS-Endpoint-Automation` ADR-0002, taken on the same day, for the
same reason: a reader now brings the question *which of this can I hand to a model?*, and an
answer given in prose is wrong within a model generation.

## Decision

**1. A verification row is a command or an API call, plus what it must return.** This
repository already passes that rule everywhere a phase has run — every row in phases 1, 2 and 5
names a command and the output that was seen. Phases 3, 4 and 6 are specifications and name the
tier that could produce each row. The audit is one line: **0 rows GUI-only, 0 rows without a
command among the phases that ran.** The rule is recorded so that it binds what is written next.

**2. Sections written from now on open with the same five headings**: **Before you start** ·
**Permissions** · **Minimum test** · **Verify** · **Rollback**. Phases 1, 2 and 5 already carry
*Prerequisites*, a verification table and an acceptance; they are not rewritten, and get the
block when they are next touched.

**3. The agent boundary is a ledger, [`AGENT_BOUNDARY.md`](../../AGENT_BOUNDARY.md).** One row
per **Responsibility Item**, four lines — *Human decides / Agent executes / How / How you know
it worked* — and a **model line**: exact model identifier, where it ran, the date. A model that
did not run the task has no line. A run leaves a file in [`lab/agent-runs/`](../../lab/agent-runs/),
and that file is what turns a 🧭 row into a 🔨 one. When a model generation changes the old
line stays and a new one is added. A line older than 90 days, or from a superseded
generation, is ⏳ until re-run.

One thing is specific to this chain and is written into the ledger's first paragraph: **the
model inside the sandbox and the model doing the operator's work are two actors.** Every ledger
row is about the second. Row 5.2 — which model endpoint the sandbox may reach — is ⛔ for the
operator agent on principle, because an agent that chooses its own model has moved the boundary
this chain exists to hold.

**4. A run is made through an agent CLI when the responsibility needs tools** (`claude -p`,
`codex exec`; a local model through `codex exec --oss --local-provider ollama|lmstudio`) **and
through a bare API call when it does not.** At least three models per row — the current hosted
default from two vendors and one local model — so the hosted/local gap is on the same task in
the same table. The runner script lives in `SE-macOS-Endpoint-Automation/lab/agent/`; it is not
duplicated here until a row here needs the bare-API path.

**5. Transcripts are public, so they are screened.** `lab/check_secrets.sh` runs over
`lab/agent-runs/` before anything is committed and refuses on a hit.

## What this does not change

The markers (ADR-0001). The private/public split. The fact that phases 3, 4 and 6 stay 🧭 until
a tier exists that can run them — the ledger does not get rows for them either, for the same
reason.
