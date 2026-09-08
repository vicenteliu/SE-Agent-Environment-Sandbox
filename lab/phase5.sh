#!/bin/bash
# Phase 5 — environment definition → image → chosen tier → model endpoint reachable from inside the rollout.
set -u
LAB=/var/lab; cd $LAB
echo "== hop 1: definition validated (required keys present, tier is one of the four) =="
jq -e '.name and .image and (.tier|IN("host","runtime","gvisor","microvm")) and .limits.memory and .model_endpoint and .done_when' env.json >/dev/null && echo "env.json: valid  name=$(jq -r .name env.json) tier=$(jq -r .tier env.json)"
echo "== hop 2: image is content-addressed =="
echo "digest=$(podman image inspect --format '{{.Digest}}' localhost/lab-env)  size=$(podman image inspect --format '{{.Size}}' localhost/lab-env | awk '{printf "%.0f MB", $1/1048576}')"
echo "== hop 3: rollout under the tier the definition names, limits from the definition =="
MEM=$(jq -r .limits.memory env.json); CPUS=$(jq -r .limits.cpus env.json); PIDS=$(jq -r .limits.pids env.json); MODEL=$(jq -r .model env.json); EP=$(jq -r .model_endpoint env.json)
RUN="podman run --rm --runtime /usr/local/bin/runsc --memory $MEM --cpus $CPUS --pids-limit $PIDS localhost/lab-env"
podman rm -f -t 0 rollout-1 >/dev/null 2>&1; podman run -d --replace --name rollout-1 --runtime /usr/local/bin/runsc --memory $MEM --cpus $CPUS --pids-limit $PIDS localhost/lab-env sleep 60 >/dev/null
echo "outside: runtime=$(podman inspect -f '{{.OCIRuntime}}' rollout-1)  memory=$(podman inspect -f '{{.HostConfig.Memory}}' rollout-1)  pids=$(podman inspect -f '{{.HostConfig.PidsLimit}}' rollout-1)  cpus=$(podman inspect -f '{{.HostConfig.NanoCpus}}' rollout-1)"
echo "inside:  $(podman exec rollout-1 sh -c 'echo kernel=$(uname -r) hostname=$(hostname)')"
podman rm -f -t 0 rollout-1 >/dev/null 2>&1
echo "== hop 4: model endpoint reachable from inside the rollout =="
curl -s -m 120 $EP/api/generate -d "{\"model\":\"$MODEL\",\"prompt\":\"hi\",\"stream\":false}" >/dev/null   # warm-up from the VM: loads the model, so the measured number is the request, not the load
t0=$(date +%s%N)
OUT=$($RUN sh -c "curl -s -m 60 $EP/api/generate -d '{\"model\":\"$MODEL\",\"prompt\":\"Reply with the single word: ready\",\"stream\":false}'")
t1=$(date +%s%N)
echo "latency_ms=$(( (t1-t0)/1000000 ))  response=$(echo "$OUT" | jq -r '.response' | tr -d '\n' | cut -c1-60)  eval_count=$(echo "$OUT" | jq -r '.eval_count')"
echo "== boundary check: the rollout cannot see the host's processes or the lab directory =="
echo "procs_visible=$($RUN sh -c 'ls /proc | grep -c "^[0-9]"')  lab_dir=$($RUN sh -c 'ls /var/lab 2>&1 | head -1')"
