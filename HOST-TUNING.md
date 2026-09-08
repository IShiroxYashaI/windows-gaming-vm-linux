# Host tuning for the win11 VFIO VM

Companion to [[KVM-STEALTH]]. That document is about *detection*; this one is
about *frametime, latency and maintenance*. *None of the changes here affect the
VMAware score* — 0/85 is unchanged by all of it.

Written 2026-09-07, after an audit of the running host.

For the day-to-day commands rather than the reasoning, see [[VM-RUNBOOK]].

---

## What was actually wrong

Every number below was measured on the live host, not estimated.

| Finding | Evidence |
|---|---|
| **vCPU threads were preempted ~237×/sec** | `CPU 10/KVM`: 1,264,700 involuntary context switches in 89 min of VM uptime |
| **Nothing isolated the pinned cores** | `system.slice`, `user.slice`, `init.scope` all showed `cpuset.cpus.effective: 0-47`. Hyprland was sitting on core 23 |
| **QEMU ran at nice 9** | ananicy-cpp's `00-default/Tools/qemu.rules` tags it `Heavy_CPU` = `{ nice 9, ioclass best-effort, ionice 7 }` |
| **Guest disk I/O was deprioritised** | that same rule's `ionice 7` is the *lowest* best-effort priority. The guest disks are raw SATA passthrough, so this made the known WD Green write-stall worse |
| **Host IRQs landed on the VM cores** | `xhci_hcd` irq97 alone delivered **4,030,645** interrupts to cores 18-23,42-47 — the 1000 Hz Razer mice |
| **Guest RAM had zero huge pages** | `HugePages_Total: 0`, `ShmemPmdMapped: 0`. 32 GiB on 4 KiB pages, so every guest TLB miss is a two-dimensional walk under NPT |
| **Unstable disk paths** | the domain referenced `/dev/sda` and `/dev/sdc` |
| **Stale comment in `root-step10-kvm-swap.sh`** | claimed "a reboot always restores stock", untrue since `kvm-stealth.service` was installed |

The `Heavy_CPU` tag is the root of the first four rows: nice 9 loses every race
against a host task at nice 0, and it was doing that on cores it was supposed to
own exclusively.

---

## The intercept knobs survive a guest restart

This is the one correctness bug, as opposed to a performance one.

`stealth_no_cpuid_intercept` and `stealth_no_rdpru_intercept` are **host module
parameters**. They are not part of domain state, so shutting the VM down and
starting it again leaves them exactly as they were. A cold start after `max-on`
would therefore have Windows enumerate topology against *raw host CPUID* —
24C/48T instead of the configured 6C/12T — which is precisely what the comments
in `root-step10-kvm-swap.sh` warn against.

The libvirt hook closes this on the `prepare` path.

> **It does not close the in-guest case.** The domain has
> `<on_reboot>restart</on_reboot>`, so a restart from inside Windows resets QEMU
> **in place** and libvirt fires **no hook at all**. Before restarting Windows
> from the guest, run `sudo ./root-step10-kvm-swap.sh max-off` yourself.
>
> A `virsh event --domain win11 --event reboot` watcher could automate this. It
> is not installed — it is an extra always-on daemon for a case that is easy to
> handle by hand.

---

## What is installed

### `/etc/libvirt/hooks/qemu`

Source of truth: `hooks/qemu` in this repo. Installed 2026-09-08; the stub
`exit 0` hook that was there before is preserved at `qemu.pre-step13.bak`.
`./check.sh` verifies it is present and ours.

| libvirt phase | action | why |
|---|---|---|
| `prepare/begin` | reset both intercept knobs to `0` | Windows must enumerate topology through the emulated CPUID path |
| `started/begin` | `AllowedCPUs=0-17,24-41` on `system.slice`, `user.slice`, `init.scope` | takes host tasks off the pinned vCPU cores |
| `release/end` | `AllowedCPUs=0-47`, reset knobs again | hand the cores back |

Two design constraints worth remembering:

- **A non-zero exit from `prepare` aborts the domain start.** The hook has no
  `set -e`, guards every write, and ends in an unconditional `exit 0`. The
  `test` mode asserts this, including in the unprivileged case.
- **QEMU is in `machine.slice`, not `system.slice`**, so confining the host
  slices does not touch it. `machine.slice` stays at `0-47`; libvirt's own
  `vcpupin`/`emulatorpin` do the placement. Verified before shipping.

The cpuset changes use `systemctl set-property --runtime`, so they are not
persisted and a bad state self-heals on the next host reboot.

### `/etc/ananicy.d/99-local/qemu-vfio.rules`

`99-` sorts after `00-default`, so it wins.

```json
{ "name": "qemu-system-x86",    "nice": 0, "ioclass": "best-effort", "ionice": 0 }
{ "name": "qemu-system-x86_64", "nice": 0, "ioclass": "best-effort", "ionice": 0 }
```

`comm` is truncated to 15 characters, hence both spellings. `nice 0` rather than
a negative value: once the cpuset isolation is in place the vCPUs have exclusive
cores and nice barely matters for them, so there is no reason to let the emulator
threads on 1-2,25-26 preempt host work. `ionice 0` is the half that matters —
it undoes the I/O deprioritisation of the passthrough disks.

---

## Usage

```bash
sudo ./root-step13-vm-tuning.sh install      # hook + ananicy rule, reloads libvirtd
sudo ./root-step13-vm-tuning.sh apply-now    # same cpuset change, for a VM already running
sudo ./root-step13-vm-tuning.sh status       # what is in effect, plus live preemption counters
sudo ./root-step13-vm-tuning.sh revert-now   # give all cores back, VM keeps running
sudo ./root-step13-vm-tuning.sh remove       # full undo, restores any pre-existing hook
./root-step13-vm-tuning.sh test              # no root needed, no VM needed
```

`install` only takes effect on the next VM start. For a VM that is already up,
`apply-now` does the cpuset half immediately; ananicy re-scans on its own after
the restart that `install` performs.

`install` reloads the active libvirt daemon (`libvirtd` here, `virtqemud` on a
modular setup) because libvirt caches which hooks exist at daemon startup and
will not notice a newly created hook file otherwise. A reload does not disturb
running domains.

---

## Also changed

**Disks now use stable paths.** The domain referenced `/dev/sda` and `/dev/sdc`,
which are enumeration-order dependent:

```
/dev/disk/by-id/ata-WDC_WDS240G2G0A-00JH30_20161A805100   (was /dev/sda)
/dev/disk/by-id/ata-SSD_256GB_XXXXXXXXXXXXX               (was /dev/sdc)
```

Both were confirmed to resolve to the expected devices before the change. This
is host-side only — the guest-visible `<serial>` values are the spoofed ones and
are untouched, so there is no stealth impact.

**`root-step10-kvm-swap.sh` header corrected** — it claimed a reboot always
restores stock, which stopped being true when `kvm-stealth.service` was
installed. It now also documents the guest-restart behaviour of the max-* knobs.

---

## Measured after the install (2026-09-08)

The hook fired on the first real VM start — `prepare` reset the knobs, `started`
confined the slices — and ananicy applied `nice 0 / ionice 0` instead of
`nice 9 / ionice 7`.

| | before | after |
|---|---|---|
| worst vCPU involuntary switches | **237/s** | **73/s** |
| typical vCPU | — | 22–67/s |

Measured as a 60-second delta on a running guest, so Windows boot is excluded.
A ~3.3× improvement on the worst case, and it is real — but it is **not** the
"single digits" this document previously predicted. That prediction was wrong,
and the reason is worth recording.

**cgroup cpusets only move userspace.** Confirmed both ways: every host
userspace thread now reports `Cpus_allowed_list: 0-17,24-41` and genuinely
cannot be scheduled on the VM cores, while kernel threads (`kworker`, `nv_queue`)
still report `0-47` because `AllowedCPUs` on a slice does not constrain them.
(Beware `ps -o psr` here — it reports the *last* CPU a thread ran on, so
sleeping threads keep showing a VM core long after they were confined. That
reads as a failure when it is not; check `Cpus_allowed_list` instead.)

So what remains is kernel threads and interrupts, neither of which a cpuset can
touch. Interrupts landing on 18-23,42-47, measured over 30s:

| irq | rate | source | verdict |
|---|---|---|---|
| 188 | 636/s | `vfio-msi` for the Quadro at `42:00.0` | **legitimate** — the passthrough GPU serving the guest. Must stay |
| 97 | 188/s | `xhci_hcd` at `4a:00.0` — the 1000 Hz Razer mice | host noise, should not be here |
| 106, 114 | ~2/s | NVMe queues | negligible |

That makes the IRQ affinity change below the main remaining lever, not a
secondary one: roughly 190/s of pure host interrupt noise is still hitting the
gaming cores.

---

## Still outstanding — these need a host reboot

Both are real and measured, neither is done.

**1. Move host IRQs off the VM cores.** Add to the kernel command line:

```
irqaffinity=0-17,24-41
```

This is now the highest-value remaining change — see the measurements above.

`isolcpus=managed_irq,domain,18-23,42-47` would additionally move the managed
NVMe queues, at the cost of taking those cores out of the scheduler entirely —
a bigger hammer, and it overlaps with what the cpuset isolation already does.
Start with `irqaffinity` alone and re-measure.

**Check irq188 afterwards.** `irqaffinity=` sets the default mask for interrupts
allocated at boot, but the Quadro's `vfio-msi` vectors are allocated when the VM
starts and it is not certain they escape the default. They are at 636/s and
belong on the VM cores; if the change pushes them onto host cores, GPU
interrupts start costing a cross-core hop. Verify with

```bash
grep -E 'vfio-msi|xhci' /proc/interrupts
cat /proc/irq/188/smp_affinity_list
```

and pin it back with `echo 18-23,42-47 > /proc/irq/188/smp_affinity_list` if it
moved.

**2. Reserve huge pages at boot.** Runtime allocation is not realistic — after a
few hours of uptime the host is too fragmented. Add `hugepagesz=2M hugepages=16640`
(32 GiB) to the kernel command line and `<memoryBacking><hugepages/></memoryBacking>`
to the domain. Note the guest RAM is currently memfd/shared; hugetlb preserves
shared backing, so this does not break anything that depended on it.

---

## Deliberately not done

| | |
|---|---|
| **Toggle-script atomicity** | Raised in an audit; not a real issue. The patch syncs intercept state inside `svm_vcpu_run()`, per-vCPU, on the next VM entry — microseconds. The script also reads the values back immediately, so a failed write is visible |
| **CPUID consistency while `max-on`** | Real, inherent, and already documented in [[KVM-STEALTH]] and in the script comments. There is no fix: `INTERCEPT_CPUID` is one bit, all-or-nothing. It is an accepted trade |
| **SMBIOS core counts** | The firmware table says 24 total / 8 enabled / 16 threads against an actual 6/12. A genuine inconsistency, but it needs a `smbios.bin` rebuild and detectors rarely cross-check it against CPUID. Low value, non-zero risk |
| **Moving the Quadro to an x16 slot** | The card *is* limited: its parent root port `40:03.1` has `max_link_width: 4`, so a x16 Gen3 card runs Gen3 x4 (~3.9 GB/s). But this is not a slot swap — moving it changes the PCI address, which breaks the `<hostdev>` entries, the vfio bind, and possibly the IOMMU grouping, and it needs BIOS bifurcation changes. Worth doing deliberately, not casually |

---

## Verification status

| | |
|---|---|
| hook syntax, guest filtering, unknown-op handling, unprivileged `exit 0` | **verified** via `test` |
| ananicy rule JSON validity, override ordering | **verified** |
| by-id paths resolve correctly, domain redefined | **verified** |
| `machine.slice` unaffected by slice confinement | **verified** |
| `libvirtd` supports SIGHUP reload | **verified** |
| installed artifacts byte-identical to the repo; previous hook backed up | **verified** 2026-09-08 |
| `libvirtd` active after the reload; ananicy reloaded the rule | **verified** 2026-09-08 |
| hook firing on a real domain start; post-change preemption counts | **measured** 2026-09-08 — see above |
