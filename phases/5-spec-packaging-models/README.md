# Phase 5 — Environment definition, packaging, and a model to talk to

> From a definition a human or an agent wrote, to a rollout running under the tier it named, with
> a model endpoint reachable from inside.

🔨 lab **Run on the minimum tier** end to end for one environment. 🧭 The definition format is a
minimal example, not a specification of the format.

| # | Hop | Marker | What it answers |
|---|---|---|---|
| 1 | **Definition validated** | 🔨 lab (🧭 the format) | What an environment author is allowed to say, checked before anything is built |
| 2 | **Image, content-addressed** | 🔨 lab | The rollout's identity is a digest, not a tag |
| 3 | **Rollout under the named tier, with the named limits** | 🔨 lab | The tier is chosen by the definition, not by the default |
| 4 | **Model endpoint reachable from inside** | 🔨 lab | A small model served on the host, answering a request from inside the sandbox |
| 5 | **Boundary check** | 🔨 lab | What the rollout cannot see |

## Prerequisites

- Phase 1's image and gVisor runtime.
- A model served on the host by any local server that speaks HTTP — the lab uses a small
  instruction-tuned model behind a local serving API on the workstation, reached from the VM
  over a reverse tunnel so the server stays bound to loopback on the host.
- A definition file. The lab's is nine keys: name, image, tier, limits (memory / cpus / pids),
  tools, model endpoint, model, and the *done* condition.

## Hop 1 — definition validated

`jq -e` asserts the keys exist and the tier is one of the four. That is the whole validator, and
it is enough to make the point: a definition an agent wrote is checked by the same rule a human's
is, before a container is created. 🧭 A real format needs a schema, versioning, and a policy for
which tools a class may name; none of that is here and the marker says so.

## Hop 2 — image, content-addressed

The image built from the three-line `Containerfile` has a digest; the digest, not the tag, is
what a rollout is identified by, because the tag can move and the digest cannot.

## Hop 3 — rollout under the named tier

The definition says `gvisor`, so the rollout runs with `--runtime runsc`; the limits in the
definition become the container's memory, CPU and pids limits. Inside, `uname -r` reports
gVisor's kernel version, not the host's.

## Hop 4 — model endpoint reachable

From inside the rollout, one HTTP request to the model endpoint the definition names, asking for a
one-word answer. The latency includes the model's generation time and is recorded as one number
because that is what an agent inside the environment experiences.

## Hop 5 — boundary check

`ls /proc` from inside shows the rollout's own processes only; the lab directory on the VM does
not exist from inside. Neither is a security claim — it is the observable shape of the boundary
the definition asked for.

## How the phase fails

- **The model server bound to all interfaces to make it reachable.** The lab kept it on loopback
  and tunnelled; an environment platform should route, not expose.
- **Tags instead of digests.** Two rollouts of "the same image" that were not.
- **A definition that names a tier the host cannot run.** The validator accepts `microvm`; the
  minimum tier cannot run it; the failure should be at validation against the tier's list, not at
  container start.

## Verification

One run on the minimum tier, after one warm-up request from the VM so the model was loaded
before the measured request.

| | Command | Result |
|---|---|---|
| 1 | `jq -e '.name and .image and (.tier|IN("host","runtime","gvisor","microvm")) and .limits.memory and .model_endpoint and .done_when' env.json` | `valid  name=shell-tools-v1 tier=gvisor` |
| 2 | `podman image inspect --format '{{.Digest}}'` | `sha256:382d0859…` · 341 MB |
| 3 | `podman run --runtime runsc --memory 512m --cpus 2 --pids-limit 256` from the definition; `podman inspect` outside, `uname -r` inside | outside `runtime=runsc memory=536870912 pids=256 cpus=2000000000` · inside `kernel=4.19.0-gvisor` |
| 4 | from inside: `curl $endpoint/api/generate -d '{"model":…,"prompt":"Reply with the single word: ready","stream":false}'` | **224 ms**, response `ready`, 2 tokens — a small model on the host, over the VM's bridge gateway |
| 5 | inside: `ls /proc \| grep -c '^[0-9]'` · `ls /var/lab` | `procs_visible=3` · `No such file or directory` |

## Acceptance

One definition, validated, built to a digest, run under the tier it named with the limits it
named, and a request to the model endpoint answered from inside the rollout.

## Escape Hatch

If no model can be served on the host, the endpoint hop is replaced by any HTTP service on the
host and the phase is accepted with the marker on hop 4 downgraded to 🧭 — reachability was shown,
the model was not.
