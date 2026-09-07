# Patched QEMU sources

Copies of the files edited inside `AutoVirt/src/v11.0.3/`, kept here because
`AutoVirt/` is an upstream git repo with its own remote and is gitignored.

These are **copies for reference and recovery** — the build uses the originals
under `AutoVirt/src/`. To reproduce the edits on a fresh AutoVirt checkout, run
`../apply-my-qemu-changes.sh`; diff against these if it drifts.

`target/i386/kvm/kvm.c` no longer contains the `KVM_CAP_DISABLE_QUIRKS2` /
`QUIRKDBG` hunk — it was proven to do nothing (the real fix was
`stealth_vmcall_ud`) and was reverted 2026-09-07.
