# windows-gaming-vm-linux

A Windows 11 gaming VM on a Linux host, with the GPU passed through via VFIO. The work covers the whole stack: host scheduling and interrupt tuning, patched QEMU/OVMF firmware, an out-of-tree patched KVM module, and the scripts that keep all of it working across reboots and kernel updates.

Every change here was measured before and after on the live host. When a result missed its prediction, the docs record why.

| | |
|---|---|
| **Host** | AMD Threadripper 7960X (24C/48T, 4 CCDs) · ASUS Pro WS TRX50-SAGE · CachyOS |
| **Guest** | Windows 11 IoT Enterprise LTSC 2024 · 12 vCPUs pinned 1:1 to one CCD · `host-passthrough` |
| **GPU** | NVIDIA Quadro RTX 6000 (VFIO passthrough), headless via an EDID override |
| **Stack** | libvirt · QEMU 11 (patched) · OVMF/EDK2 · KVM (patched, built out-of-tree) · systemd · Bash · Python · C |

---

## Highlights

**Host performance tuning** ([HOST-TUNING.md](HOST-TUNING.md))
- Traced vCPU stutter to a root cause: `ananicy-cpp` tagged QEMU as `Heavy_CPU`, which meant `nice 9` and `ionice 7` on cores the VM was supposed to own. Worst-case vCPU preemption dropped from **237/s to 73/s**, about **3.3×**.
- Added a libvirt hook that confines host userspace to the non-VM cores (cgroup cpusets) when the guest starts, and undoes it on shutdown.
- Measured what cpusets *can't* move (kernel threads and IRQs) and identified ~190/s of USB interrupt noise on the gaming cores as the next lever. IRQ affinity and boot-time huge pages are planned, since both need a host reboot. Guest disks moved to stable `/dev/disk/by-id` paths.

**Patched KVM, built safely** ([KVM-STEALTH.md](KVM-STEALTH.md))
- Only `arch/x86/kvm` is rebuilt, against the distro's own source tarball for the *running* kernel. Seeding `Module.symvers` avoids a full `vmlinux` build, so a rebuild takes minutes.
- Nothing is written to `/lib/modules`. A `vermagic` check refuses mismatched builds, and modules are hot-swapped with `modprobe -r` / `insmod`. Booting without the systemd unit gives you stock KVM.
- Six module parameters ("knobs") change specific SVM intercept and exception behaviour. Each is documented with its trade-offs.

**Bare-metal fidelity research**
- [VMAware](https://github.com/kernelwernel/VMAware)'s detection score is used as a measurable metric for how closely the guest behaves like real hardware: **8/85 → 0/85**.
- The goal was to understand *which* signals have a mechanical cause (fixable) and which are architectural (not). Approaches that were tried and failed are documented too. RDTSC/TSC is deliberately left alone, and nothing here claims to defeat kernel-level anti-cheat.
- Firmware work: ACPI tables and the FACP rebuilt from the host's own, SMBIOS built from the real board, and OVMF built and provisioned with Secure Boot keys.

**Operations**
- `check.sh` is a single no-root command that checks the kernel, modules, taint bits, knobs, systemd unit, libvirt hook, ananicy rule, core isolation and the running VM. It prints the exact fix for anything that's wrong.
- [VM-RUNBOOK.md](VM-RUNBOOK.md) covers the everyday procedures: restarts, host reboots, kernel updates, reinstalling from scratch, and a throwaway `win11-lab` sandbox (an overlay on a golden image).

---

## Start here

```bash
./check.sh          # no root needed: is everything as it should be?
```

| Document | What's in it |
|---|---|
| **[VM-RUNBOOK.md](VM-RUNBOOK.md)** | **Start with this one.** What to run when restarting the VM, after a host reboot, or after a kernel update |
| [HOST-TUNING.md](HOST-TUNING.md) | Frametime and latency: core isolation, the ananicy fix, IRQ affinity, huge pages, with before/after measurements |
| [KVM-STEALTH.md](KVM-STEALTH.md) | The patched KVM module: build method, the six knobs, what worked, what failed, and the trade-offs |

## Common tasks

| I want to… | Run |
|---|---|
| check everything | `./check.sh` |
| restart the VM | `sudo ./root-step10-kvm-swap.sh max-off` first, `max-on` after Windows is up |
| restore the full configuration after a host reboot | `sudo ./root-step10-kvm-swap.sh max-on` (once Windows is up) |
| rebuild after a kernel update | `./kern-prep.sh && ./apply-patch.sh && ./kern-build-kvm.sh patched` |
| install the host tuning | `sudo ./root-step13-vm-tuning.sh install` |
| give the guest a display with no monitor attached | load `edid/host-DP-1.bin` in NVCP → Workstation → View System Topology (see the runbook) |
| undo everything | `sudo ./root-step13-vm-tuning.sh remove`, `sudo ./root-step12-persist.sh remove`, reboot |

The `max-off` before a restart is not optional: some knobs are host module parameters that survive a guest restart. The runbook explains why.

The scripts work from any directory. `check.sh` prints its suggested fixes as absolute paths.

---

## Scripts

**Kernel / KVM.** Every version-dependent path is derived from `uname -r`, so nothing needs editing after a kernel update.

| Script | Purpose |
|---|---|
| `kver.sh` | Sourced by the scripts below; derives paths and the expected vermagic, aborts on mismatch |
| `kern-prep.sh` | Fetches the matching CachyOS tarball if absent, extracts and configures it |
| `apply-patch.sh` | Applies `kernel-patches/kvm-stealth.mypatch`; idempotent, refuses to half-patch |
| `kern-build-kvm.sh` | Builds `M=arch/x86/kvm`; fails if the result's vermagic is wrong |
| `regen-patch.sh` | Regenerates the patch by diffing the tree against the pristine tarball |
| `add-knob3.py` … `add-knob6.py` | Idempotent source editors that add the knobs, for when the patch stops applying |
| `root-step10-kvm-swap.sh` | Loads or unloads module builds and toggles the knobs |
| `root-step12-persist.sh` | Installs the boot-time swap (`kvm-stealth.service`) |

**Host tuning.**

| Script | Purpose |
|---|---|
| `root-step13-vm-tuning.sh` | The libvirt hook and ananicy override; `install` / `status` / `test` / `apply-now` |
| `hooks/qemu` | The hook itself (installed to `/etc/libvirt/hooks/qemu`) |
| `ananicy/99-local/qemu-vfio.rules` | Undoes ananicy's `Heavy_CPU` tag on QEMU |
| `root-step8-cpu-isolation.sh` | *Superseded by step 13.* Does the same cpuset change by hand and must be re-run after every reboot |
| `root-step11-boot-entry.sh` | Adds a separate systemd-boot entry with `mitigations=off` |

**Firmware / QEMU.** None of this is affected by a kernel update.

| Script | Purpose |
|---|---|
| `root-step1.sh`, `root-step3-facp-extra.sh` | Dump the host FACP/ACPI fields the override is built from |
| `edk2-prep.sh`, `edk2-build.sh`, `mkvars.sh` | Build OVMF and provision `OVMF_VARS.fd` |
| `root-step4-install-ovmf.sh` | Installs the built firmware |
| `apply-my-qemu-changes.sh` | Reproduces the QEMU source edits from pristine v11.0.3 |
| `root-step2-install.sh`, `root-step5`, `root-step7*`, `root-step9-*` | Build and install the patched QEMU into `/opt/AutoVirt` |
| `root-step6-smbios.sh` | Installs the custom SMBIOS table |
| `rollback-to-11.0.0.sh` | Restores the pre-project QEMU from backup |
| `cycle-and-view.sh` | Shuts down, restarts and reattaches to the VM |

`libvirt/*.xml` are reference copies of the domain definitions. Nothing applies them automatically.

`edid/` holds EDIDs read from the host's own monitor connectors. The Quadro's EDID override uses them to give the guest a real WDDM display head with nothing plugged in.

---

## Notes

**Hardware identifiers are placeholders.** The disk serials, domain UUIDs and MAC addresses in `libvirt/*.xml`, the monitor serials in `edid/*.bin`, and the SSD serial in `build-lab.sh` are made up. Substitute your own before defining a domain or running `build-lab.sh`. It refuses to wipe anything until `SSD_BYID` names a real disk.

**Not in git:** kernel source (~4 GB, re-fetched by `kern-prep.sh`), upstream QEMU checkouts (the edited files are mirrored in `qemu-patched-sources/`), built modules, logs and backups. `kmod/` is excluded on purpose: modules are only valid for the kernel they were built against, and loading a stale pair after an update silently corrupts struct offsets. `check.sh` verifies this on every run.

**Scope.** This is my personal setup, documented for reference. It targets one specific machine and kernel series. Read the scripts before running anything as root, and check that your use complies with the terms of the software you run in the guest.
