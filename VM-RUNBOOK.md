# win11 VM — everyday runbook

The short operational card. The reasoning behind all of it is in
[[KVM-STEALTH]] (detection) and [[HOST-TUNING]] (frametime and maintenance).

All paths below are relative to `~/vfio-acpi/build/`.

---

## Restarting the VM

**Always `max-off` first.** The two max-* knobs are *host* module parameters —
they do not care that the guest went away. If Windows boots while they are on it
enumerates **raw host CPUID**: 24C/48T instead of the configured 6C/12T.

```bash
sudo ./root-step10-kvm-swap.sh max-off     # BEFORE restarting
#   ... restart Windows, wait for the desktop ...
sudo ./root-step10-kvm-swap.sh max-on      # AFTER it is up  → 0/85
```

This applies to **both** kinds of restart — a restart from inside Windows *and*
`virsh shutdown` + `virsh start`.

> If you forget, it is not fatal. Run `max-off` and restart Windows again.

Once `root-step13-vm-tuning.sh install` has been run, the libvirt hook does the
`max-off` half automatically — but **only** for `virsh shutdown`/`start`. The
domain has `<on_reboot>restart</on_reboot>`, so a restart from inside Windows
resets QEMU in place and libvirt fires no hook at all. That case is always
manual.

| how you restart | hook installed? | what you run |
|---|---|---|
| from inside Windows | either | `max-off` before, `max-on` after |
| `virsh shutdown` + `start` | no | `max-off` before, `max-on` after |
| `virsh shutdown` + `start` | yes | just `max-on` after |

---

## After a host reboot

`kvm-stealth.service` loads the **patched** build with the four safe knobs on,
so you come back at **1/85** automatically. The max-* knobs are never set by the
service, so they are always off after a reboot.

```bash
#   ... start the VM, wait for the Windows desktop ...
sudo ./root-step10-kvm-swap.sh max-on      # → 0/85
```

Nothing else is needed. The hook and the ananicy rule are real files in `/etc`
and survive reboots on their own. The cpuset changes are `--runtime` on purpose
and get reapplied by the hook on the next VM start.

---

## After a kernel update

**The modules must be rebuilt.** The `.ko` files in `kmod/` are valid only for
the kernel they were built against (`7.2.2-1-cachyos`).

```bash
uname -r                                   # what is running now
modinfo kmod/patched/kvm-amd.ko | grep vermagic     # what the modules expect
```

If those disagree:

```bash
./kern-prep.sh                             # fetch the matching kernel source
patch -p1 -d cachy/<new-version> < kernel-patches/kvm-stealth.mypatch
./kern-build-kvm.sh patched
sudo ./root-step10-kvm-swap.sh patched
```

Until you do, `kvm-stealth.service` fails safely: `insmod` is rejected on the
vermagic mismatch, the script's `fail_restore` loads the distro modules, and the
VM runs normally with no stealth (back to 8/85). Nothing breaks, you just lose
the patch.

Never use `insmod -f`. Check afterwards that `/proc/sys/kernel/tainted` does
**not** have bit 1 (`TAINT_FORCED_MODULE`, value 2) set — if it does, the source
did not match and the module is not safe to run.

---

## Checking state

```bash
sudo ./root-step13-vm-tuning.sh status     # hook, ananicy, cpusets, knobs, preemption
grep . /sys/module/kvm*/parameters/stealth_*        # all six knobs at a glance
```

Expected when everything is on: four `Y` from `patched`, plus
`stealth_no_cpuid_intercept:Y` and `stealth_no_rdpru_intercept:Y` from `max-on`.

---

## If something is wrong

```bash
sudo ./root-step10-kvm-swap.sh max-off     # first: undo the risky pair
sudo ./root-step10-kvm-swap.sh restore     # back to distro KVM (VM must be down)
sudo ./root-step13-vm-tuning.sh remove     # undo the host tuning
sudo ./root-step12-persist.sh remove       # stop loading patched modules at boot
```

A host reboot with `kvm-stealth.service` disabled always returns you to a
completely stock KVM. Nothing was ever written to `/lib/modules`.
