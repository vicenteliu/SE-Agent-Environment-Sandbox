# The lab — what actually ran

These are the files the runs on the phase pages came from, byte for byte. A script is here
because it was run; there are no scripts here for the ⛔ hops.

| File | Used by |
|---|---|
| `Containerfile` | the one image every tier runs — a workload generator, `curl`, nothing else |
| `env.json` | phase 5's environment definition |
| `phase1.sh` | isolation tiers 0–3 with startup and throughput |
| `phase2.sh` | ZFS snapshot / clone, CRIU checkpoint / two restores, the TCP refusal |
| `phase5.sh` | definition → image digest → rollout under the named tier → model endpoint → boundary check |

## The minimum tier, reproduced

A Linux VM on an Apple-silicon workstation. Any Linux machine with cgroup v2 works; the VM is
only how the author has one.

```sh
# host (macOS): a Linux VM via Lima
brew install lima
limactl start --name=sandbox --tty=false --cpus=4 --memory=8 --disk=40 template://ubuntu-24.04
limactl shell sandbox
```

```sh
# inside the VM, as root
apt-get install -y runc crun podman skopeo umoci zfsutils-linux util-linux stress-ng jq
add-apt-repository -y ppa:criu/ppa && apt-get update && apt-get install -y criu   # not in the 24.04 archive
ARCH=aarch64; URL=https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH}
curl -fsSLO ${URL}/runsc && curl -fsSLO ${URL}/runsc.sha512 && sha512sum -c runsc.sha512
install -m 755 runsc /usr/local/bin/runsc
modprobe zfs
mkdir -p /var/lab && cp Containerfile env.json phase*.sh /var/lab/ && cd /var/lab
podman build -t localhost/lab-env -f Containerfile .
cid=$(podman create localhost/lab-env); mkdir rootfs; podman export $cid | tar -x -C rootfs; podman rm $cid
bash phase1.sh; bash phase2.sh
```

For phase 5 a model has to answer from the host. The lab served a small instruction-tuned model
on the host's loopback and reached it from the VM over a reverse SSH tunnel bound inside the VM,
so the container on the bridge network reaches the VM's gateway address and the host never
exposes the server:

```sh
# host: keep the model server on 127.0.0.1; forward a VM port back to it
ssh -f -N -F ~/.lima/sandbox/ssh.config -o ControlMaster=no -o ControlPath=none \
    -R 0.0.0.0:11435:127.0.0.1:11434 lima-sandbox        # sshd in the VM needs GatewayPorts yes
# inside the VM: env.json's model_endpoint is the podman bridge gateway on that port
bash phase5.sh
```

## What the tier cannot do

No `/dev/kvm` — Firecracker and the KVM platform of gVisor are out. No CUDA device — accelerator
state is out. See [docs/02-lab-tiers.md](../docs/02-lab-tiers.md).
