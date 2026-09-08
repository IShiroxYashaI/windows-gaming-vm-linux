# vfio-acpi/build — Windows 11 VFIO VM hardening

Work on the `win11` libvirt domain: a Windows 11 IoT Enterprise LTSC 2024 gaming
VM with a Quadro RTX 6000 passed through, on a Threadripper 7960X / CachyOS host.
Two separate efforts live here — making the guest indistinguishable from bare
metal, and making it perform well. They share nothing but the VM.

**Start here:**

```bash
./check.sh          # one command, no root: is everything as it should be?
```

It checks the kernel, the built and loaded modules, the taint bits, all six
stealth knobs, the systemd unit, the libvirt hook, the ananicy rule, core
isolation and the running VM — and prints the exact command to fix whatever is
wrong.

---

## The documents

| | |
|---|---|
| **[VM-RUNBOOK.md](VM-RUNBOOK.md)** | **Read this one.** What to run when restarting the VM, after a host reboot, after a kernel update |
| [KVM-STEALTH.md](KVM-STEALTH.md) | How the detection score went 8/85 → 0/85. The patch, the six knobs, why AMD SVM makes it possible, what was tried and failed |
| [HOST-TUNING.md](HOST-TUNING.md) | Frametime and latency: core isolation, the ananicy fix, IRQ affinity, huge pages. Changes nothing about detection |

---

## Common tasks

| I want to… | run |
|---|---|
| check everything | `./check.sh` |
| restart the VM | `sudo ./root-step10-kvm-swap.sh max-off` first, `max-on` after Windows is up |
| get back to 0/85 after a host reboot | `sudo ./root-step10-kvm-swap.sh max-on` (once Windows is up) |
| rebuild after a kernel update | `./kern-prep.sh && ./apply-patch.sh && ./kern-build-kvm.sh patched` |
| install the host tuning | `sudo ./root-step13-vm-tuning.sh install` |
| undo everything | `sudo ./root-step13-vm-tuning.sh remove`, `sudo ./root-step12-persist.sh remove`, reboot |

The `max-off` before a restart is not optional — see the runbook for why.

The `./` forms above assume you are in this directory. The scripts also work
from anywhere if given their full path, and `check.sh` prints its suggested
fixes as absolute paths for exactly that reason.

---

## Scripts

**Kernel / KVM.** Every version-dependent path is derived from `uname -r`, so
none of these need editing after a kernel update.

| | |
|---|---|
| `kver.sh` | sourced by the rest; derives paths and the expected vermagic, aborts on mismatch |
| `kern-prep.sh` | fetch the matching CachyOS tarball if absent, extract, configure |
| `apply-patch.sh` | apply `kernel-patches/kvm-stealth.mypatch`; idempotent, refuses to half-patch |
| `kern-build-kvm.sh` | build `M=arch/x86/kvm`; fails if the result's vermagic is wrong |
| `regen-patch.sh` | regenerate the patch by diffing the tree against the pristine tarball |
| `add-knob3.py` … `add-knob6.py` | idempotent source editors that add the knobs; use these if the patch stops applying |
| `root-step10-kvm-swap.sh` | load/unload module builds and toggle the knobs |
| `root-step12-persist.sh` | install the boot-time swap (`kvm-stealth.service`) |

**Host tuning.**

| | |
|---|---|
| `root-step13-vm-tuning.sh` | the libvirt hook + ananicy override; `install` / `status` / `test` / `apply-now` |
| `hooks/qemu` | the hook itself (installed to `/etc/libvirt/hooks/qemu`) |
| `ananicy/99-local/qemu-vfio.rules` | undoes ananicy's `Heavy_CPU` tag on QEMU |
| `root-step8-cpu-isolation.sh` | **superseded by step13.** Does the same cpuset change by hand, and must be re-run after every reboot |
| `root-step11-boot-entry.sh` | adds a separate systemd-boot entry with `mitigations=off` |

**Firmware / QEMU (the earlier ACPI, SMBIOS and OVMF work).** None of this is
affected by a kernel update.

| | |
|---|---|
| `root-step1.sh`, `root-step3-facp-extra.sh` | dump the host FACP/ACPI fields the override is built from |
| `edk2-prep.sh`, `edk2-build.sh`, `mkvars.sh` | build OVMF and provision `OVMF_VARS.fd` |
| `root-step4-install-ovmf.sh` | install the built firmware |
| `apply-my-qemu-changes.sh` | reproduce the QEMU source edits from pristine v11.0.3 |
| `root-step2-install.sh`, `root-step5`, `root-step7*`, `root-step9-*` | build and install the patched QEMU into `/opt/AutoVirt` |
| `root-step6-smbios.sh` | install the spoofed SMBIOS table |
| `rollback-to-11.0.0.sh` | restore the pre-project QEMU from `/opt/AutoVirt.11.0.0-backup` |
| `cycle-and-view.sh` | shut down, restart and reattach to the VM |

`libvirt/win11.xml` is a reference copy of the domain definition, not something
that gets applied automatically.

---

## Not in git

`cachy/` and `linux-7.2*` (kernel source, ~4 GB, re-fetched by `kern-prep.sh`),
`AutoVirt/` and `qemu-cppc/` (upstream repos with their own remotes — the files
actually edited are mirrored in `qemu-patched-sources/`), `smoke/` (test
scratch), `kmod/` (built modules), and `*.log` / `*.bak`.

**`kmod/` is excluded on purpose.** The modules are valid only for the kernel
they were built against; loading a stale pair after an update is the silent
struct-offset corruption failure mode. `check.sh` verifies this every run.

## Backups

```bash
git push backup main        # → /mnt/backup/stealth_vfio/kvm-stealth.git
```

A readable snapshot lives at `/mnt/backup/stealth_vfio/kvm-stealth-build/` with
its own `BACKUP-MANIFEST.md`; the three documents are also in the Obsidian vault
at `/mnt/backup/obsidian/linux/VFIO/`.
