# Specced-Not-Run is a third marker, not a missing one

This repository inherits a two-marker honesty system — 🔨 operated for real, 🧭 mapped and
doc-checked but not run — and, following the first `SE-` playbook, keeps a third: ⛔
**Specced-Not-Run**. It adds a qualifier, **🔨 lab**, and this file says why both exist.

## ⛔ — the difference from 🧭

🧭 is *doc-checked with no plan to execute*. ⛔ carries the complete environment specification,
the step-by-step verification, the acceptance criteria, and **an explicit stated reason for not
executing**. One is an absence. The other is a decision.

Two hops carry it here. **microVM isolation** (phase 1, Firecracker) needs KVM; the author's lab
is a virtual machine on Apple silicon with no nested virtualisation, so the hop cannot be run
without hardware that is not present, and buying hardware to close a marker is the wrong order of
operations. **Accelerator state in a snapshot** (phase 2) needs a CUDA device and tooling that
exists only for it; the lab has neither. Both are specified to the point where a reader with the
right tier can run them, and the tier is named.

## 🔨 lab — the difference from 🔨

The previous playbook marked its one real run 🔨 with the words *"lab"* and *"no fleet"* in the
sentence. Here most of the 🔨 rows are lab runs, and repeating the disclaimer in prose on every row
is how a disclaimer stops being read. So the qualifier is in the marker: **🔨 lab** means real
commands and real output on one machine in a named tier — and *nothing about production*. A reader
who sees 🔨 without the qualifier is being told the author has done this where it counted.

## Why it earns its own symbol

Because the two are read differently by the only audience that matters. *"I have not done that"*
and *"here is the environment I specified to do it, what each tier can and cannot verify, and why
the tier I have stops short"* are different answers to the same question, and the second is only
available if the distinction was made while writing.

A reader who wants to build this can act on a ⛔ section. They cannot act on a 🧭 one.
