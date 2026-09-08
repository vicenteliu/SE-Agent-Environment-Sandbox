#!/bin/bash
# Phase 2 — snapshot, restore, branch: filesystem layer (ZFS) and process layer (CRIU through runc, driven by podman).
set -u
LAB=/var/lab; mkdir -p $LAB
P="podman --runtime runc"

echo "== fs layer: ZFS dataset → snapshot → two clones that diverge =="
if ! zpool list labpool >/dev/null 2>&1; then truncate -s 4G $LAB/zpool.img; zpool create -f labpool $LAB/zpool.img; fi
zfs destroy -r labpool/env 2>/dev/null; zfs create labpool/env
echo "state=0 written before snapshot" > /labpool/env/state.txt; dd if=/dev/urandom of=/labpool/env/blob bs=1M count=64 status=none
sync; zfs snapshot labpool/env@t1
zfs clone labpool/env@t1 labpool/branch-a; zfs clone labpool/env@t1 labpool/branch-b
echo "branch a wrote this" >> /labpool/branch-a/state.txt; echo "branch b wrote something else" >> /labpool/branch-b/state.txt; dd if=/dev/urandom of=/labpool/branch-b/extra bs=1M count=16 status=none; sync
echo "--- zfs list -t all (USED = what each branch costs beyond the shared snapshot) ---"; zfs list -t all -o name,used,refer,origin -r labpool
echo "--- state.txt in origin / a / b ---"; tail -n1 /labpool/env/state.txt; tail -n1 /labpool/branch-a/state.txt; tail -n1 /labpool/branch-b/state.txt
echo "--- zfs diff snapshot → branch-b ---"; zfs diff labpool/env@t1 labpool/branch-b | head -5
echo "--- restore = clone again from the same snapshot, seconds after 64 MB of divergence ---"; t0=$(date +%s%N); zfs clone labpool/env@t1 labpool/branch-c; t1=$(date +%s%N); echo "clone_ms=$(( (t1-t0)/1000000 ))  $(tail -n1 /labpool/branch-c/state.txt)"

echo "== process layer: CRIU checkpoint once, restore twice, histories diverge =="
podman rm -f -t 0 counter branch-a branch-b >/dev/null 2>&1; rm -f $LAB/counter.tar
$P run -d --replace --name counter localhost/lab-env sh -c 'i=0; while true; do i=$((i+1)); echo $i > /count; sleep 1; done' >/dev/null
sleep 8; echo "counter before checkpoint: $(podman exec counter cat /count)   runtime=$(podman inspect -f '{{.OCIRuntime}}' counter)  criu=$(criu --version | head -1)"
t0=$(date +%s%N); $P container checkpoint counter -e $LAB/counter.tar >/dev/null && t1=$(date +%s%N) && echo "checkpoint_ms=$(( (t1-t0)/1000000 ))  size=$(du -h $LAB/counter.tar | cut -f1)  state=$(podman inspect -f '{{.State.Status}}' counter)"
t0=$(date +%s%N); $P container restore -i $LAB/counter.tar -n branch-a --ignore-static-ip --ignore-static-mac >/dev/null; t1=$(date +%s%N); echo "restore_a_ms=$(( (t1-t0)/1000000 ))  count_at_restore=$(podman exec branch-a cat /count)"
sleep 5
t0=$(date +%s%N); $P container restore -i $LAB/counter.tar -n branch-b --ignore-static-ip --ignore-static-mac >/dev/null; t1=$(date +%s%N); echo "restore_b_ms=$(( (t1-t0)/1000000 ))  count_at_restore=$(podman exec branch-b cat /count)"
sleep 3
echo "--- same checkpoint, two live histories ---"; echo "branch-a count=$(podman exec branch-a cat /count)   branch-b count=$(podman exec branch-b cat /count)"

echo "--- what CRIU refuses: an established TCP connection ---"
podman rm -f -t 0 tcp >/dev/null 2>&1; rm -f $LAB/tcp.tar
HOSTPORT=$(jq -r .model_endpoint $LAB/env.json | sed 's#^http://##')
# The connection must belong to the container's own process tree: a process started by `podman exec`
# hangs off conmon, not off the container's init, and CRIU never sees it — the first version of this
# test checkpointed "successfully" for exactly that reason. So the container's main command opens it,
# as a raw TCP session to the model endpoint's port that stays established until stdin closes (an hour).
$P run -d --replace --name tcp localhost/lab-env sh -c "sleep 3600 | curl -s telnet://$HOSTPORT & while true; do sleep 1; done" >/dev/null
sleep 4
echo "established_sockets=$(podman exec tcp sh -c 'grep -c " 01 " /proc/net/tcp')   (01 = ESTABLISHED in /proc/net/tcp)"
echo "checkpoint: $($P container checkpoint tcp -e $LAB/tcp.tar 2>&1 | grep -v "^$" | tail -1 | cut -c1-160)   state_after=$(podman inspect -f "{{.State.Status}}" tcp)"
echo "criu log: $(grep -h -m1 -i "established\|tcp" $(podman inspect -f '{{.StaticDir}}' tcp 2>/dev/null)/dump.log 2>/dev/null | sed "s/^(.*) //" | cut -c1-160)"
echo "forced (--tcp-established): $($P container checkpoint tcp -e $LAB/tcp.tar --tcp-established 2>&1 | tail -1 | cut -c1-64)   size=$(du -h $LAB/tcp.tar 2>/dev/null | cut -f1)"
podman rm -f -t 0 tcp >/dev/null 2>&1
echo "== accelerator layer: no CUDA device on this tier -> SPECCED-NOT-RUN =="; ls /dev/nvidia* 2>&1 | head -1
