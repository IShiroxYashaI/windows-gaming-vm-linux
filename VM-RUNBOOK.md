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

The libvirt hook (installed 2026-09-08) does the
`max-off` half automatically — but **only** for `virsh shutdown`/`start`. The
domain has `<on_reboot>restart</on_reboot>`, so a restart from inside Windows
resets QEMU in place and libvirt fires no hook at all. That case is always
manual.

| how you restart | hook installed? | what you run |
|---|---|---|
| from inside Windows | either | `max-off` before, `max-on` after |
| `virsh shutdown` + `start` | yes (current state) | just `max-on` after |
| `virsh shutdown` + `start` | no | `max-off` before, `max-on` after |

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
the kernel they were built against — vermagic must match exactly.

```bash
uname -r                                          # what is running now
modinfo kmod/patched/kvm-amd.ko | grep vermagic   # what the modules expect
```

If those disagree, rebuild. **No script needs editing** — every version-dependent
path is derived from `uname -r` by `kver.sh`:

```bash
cd ~/vfio-acpi/build
./kern-prep.sh                             # downloads + extracts the matching source
./apply-patch.sh                           # applies kvm-stealth.mypatch (idempotent)
./kern-build-kvm.sh patched                # refuses to finish if vermagic mismatches
sudo ./root-step10-kvm-swap.sh patched     # → 1/85
#   ... start the VM, wait for the Windows desktop ...
sudo ./root-step10-kvm-swap.sh max-on      # → 0/85
```

`kern-prep.sh` fetches the tarball from the CachyOS release matching your kernel
if it is not already in `cachy/`, and aborts if the distro build tree for that
kernel is missing — install the matching headers package first.

**If the patch stops applying.** `apply-patch.sh` refuses rather than producing a
half-patched tree, and tells you so. The three files it touches (`x86.c`,
`emulate.c`, `svm/svm.c`) are active upstream, so a larger version jump can move
the anchors. The recovery is to re-add the six knobs to the new tree — the
`add-knob3.py` … `add-knob6.py` editors are idempotent and written for exactly
this — then `./regen-patch.sh` to rebuild the patch against the new tarball.

**Until you rebuild, nothing breaks.** `kvm-stealth.service` fails safe: `insmod`
is rejected on the vermagic mismatch, the script's `fail_restore` loads the
distro modules, and the VM runs normally with no stealth (back to 8/85).

Never use `insmod -f`. Check afterwards that `/proc/sys/kernel/tainted` does
**not** have bit 1 (`TAINT_FORCED_MODULE`, value 2) set — if it does, the source
did not match and the module is not safe to run.

**Not affected by a kernel update:** the ACPI/SMBIOS/OVMF/QEMU spoofing (it
lives in `/opt/AutoVirt` and firmware), the `mitigations=off` boot entry (it
references the unversioned `initramfs-linux-cachyos.img`), the libvirt hook and
ananicy rule (plain files in `/etc`), and the domain XML. Only the KVM modules
are kernel-coupled.

---

## Reinstalling Windows from scratch

Rarely needed. Done 2026-09-09 (fresh IoT Enterprise LTSC 2024) and reached
**0/85** again. There is a clean restore-point image, so a reinstall is usually
avoidable — see the last subsection.

**1. Wipe the guest disks and reset firmware.** Both are host block devices
passed straight through, so this is on the *host*, VM off:

```bash
sudo wipefs -a /dev/sda /dev/sdc                 # WD Green + the 238 GB SSD
sudo rm -f /var/lib/libvirt/qemu/nvram/win11_VARS.fd \
           /var/lib/libvirt/qemu/nvram/win11_VBS_VARS.fd
```

Removing the varstores makes libvirt re-seed a clean OVMF varstore from the
AutoVirt template on the next start — no stale "Windows Boot Manager" entry, no
leftover Red Hat certs. **Skipping the wipe is what caused the "stuck on the
ASUS logo" freeze**: boot fell through `cdrom` → `hd` to the *old* install still
on `/dev/sda`, which hung. It is not a GPU or passthrough fault.

**2. Boot the install domain.** `libvirt/win11-install.xml` is the throwaway
installer domain — same 4-function GPU passthrough and `ramfb`+SPICE as the real
one, but with the ISO wired to the cdrom and `cdrom` first in the boot order:

```bash
virsh -c qemu:///system define libvirt/win11-install.xml
virsh -c qemu:///system start  win11-install
```

Catch the **"Press any key to boot from CD or DVD"** prompt (~5 s) or it falls
through to `hd`.

**3. Watch it over SPICE, not the Quadro.** WinPE / Windows Setup renders on the
`ramfb` **primary**, not the passed-through card — the physical monitor on the
Quadro only ever shows the OVMF ASUS splash (the card has no driver yet and is
not primary). The port is `autoport`, so ask libvirt for it:

```bash
virsh -c qemu:///system domdisplay win11-install     # e.g. spice://127.0.0.1:5900
spicy -h 127.0.0.1 -p 5900 &                          # spice-gtk; virt-viewer/remote-viewer are NOT installed
```

**4. Pick the right disk.** Guest drive letters are **not** the host's:

| in the guest | host device | what it is |
|---|---|---|
| `sda` | `/dev/sda` | WD Green (WDS240G2G0A) — **install Windows here** |
| `sdb` | `/dev/sdc` | the 238 GB SSD |
| `sdc` | — | the optical drive (the ISO) |

Windows landed on guest `sda` = the WD Green; that is what the backup image is a
clone of.

**5. Switch to the real (stealth) domain and add the driver.** After setup
finishes and you have a desktop:

```bash
virsh -c qemu:///system shutdown win11-install
virsh -c qemu:///system define   libvirt/win11.xml    # hd-only boot, no ISO
virsh -c qemu:///system start    win11
```

Until a driver is installed the Quadro shows in Device Manager under **Other
devices → 3D Video Controller** (yellow ⚠), *not* under Display adapters, and
enumeration can lag — a rescan or a reboot makes it appear. Install the **NVIDIA
RTX Enterprise / Production Branch** driver (the workstation driver), **not
GeForce** — only it has the EDID Management feature the headless
`GPU_CAPABILITIES` fix needs (see the next section).

**6. Re-stealth.** Once Windows is fully settled:

```bash
sudo ./root-step10-kvm-swap.sh max-on      # → 0/85
```

If a physical monitor is plugged into the Quadro, its real EDID + WDDM head
clears `GPU_CAPABILITIES` on its own and the EDID-file override below is not
needed — keep it only for headless / Looking-Glass runs.

**Faster than reinstalling: restore the clean image.**
`/mnt/backup/stealth_vfio/win11-clean-0of85-20260909.qcow2` is a bootable clone
of the WD Green at 0/85. Restore procedure + checksum are in that folder's
`RESTORE-win11.md`; the one-liner is `qemu-img convert -O raw` back to the WD
Green **by-id** path (never a bare `/dev/sdX`). VM off, host side.

---

## The win11-lab sandbox

A disposable twin of `win11` for testing / modding without risking the real
install — the same idea as the restore image, one layer down. Built 2026-09-09
by `build-lab.sh` (one-shot, guarded; needs `--yes-wipe-ssd`).

- **`win11-lab`** boots from a qcow2 **overlay** (`/mnt/vmlab/win11-lab.qcow2`)
  stacked on a **read-only golden** (`/mnt/vmlab/win11-golden.qcow2`, a copy of
  the 0/85 image). All writes land in the overlay; the golden is never touched.
- It carries the **same spoofed serial, MAC and GPU hostdevs** as `win11` plus
  its own NVRAM, and inherits the whole host stealth stack — so it reaches the
  same **0/85** after `max-on`, and to the guest / anticheat it *is* the same
  machine.
- `/mnt/vmlab` is the old 238 GB SSD (host `/dev/sdc`), wiped and repurposed, so
  `win11` is now **single-disk** (WD Green only). The two domains **must never
  run at once** — one GPU; the second `virsh start` just fails, safely.

```bash
virsh -c qemu:///system start win11-lab     # then: max-on   (per-boot, as always)
/mnt/vmlab/reset-lab.sh                       # broke it? → back to 0/85 in ~1s (no sudo)
virsh -c qemu:///system start win11          # the real machine, unchanged
```

`reset-lab.sh` destroys the domain if running, deletes the overlay and recreates
it fresh on the golden. **To bake a new baseline** (with both VMs off): make the
golden writable, re-image the WD Green over it, restore read-only, then rebuild
the overlay —

```bash
chmod +w /mnt/vmlab/win11-golden.qcow2
qemu-img convert -O qcow2 \
  /dev/disk/by-id/ata-WDC_WDS240G2G0A-00JH30_20161A805100 /mnt/vmlab/win11-golden.qcow2
chmod 0444 /mnt/vmlab/win11-golden.qcow2
/mnt/vmlab/reset-lab.sh
```

The archival master image stays at
`/mnt/backup/stealth_vfio/win11-clean-0of85-20260909.qcow2`.

---

## The virtual monitor (EDID override)

The guest's primary display is a **monitor that does not exist**: a BenQ ZOWIE
XL LCD synthesised by the Quadro driver from a real EDID file. No dummy plug, no
cable, nothing physically attached to the card.

It is there because VMAware's `GPU_CAPABILITIES` (weight 20) asks the **primary
display driver** whether it has a hardware gamma ramp. A `ramfb` / Microsoft
Basic Display primary, or an IddCx indirect display, has none and fails the
check. A real NVIDIA WDDM head passes it. See [[KVM-STEALTH]] for the mechanism.

Set up once, in the guest. It lives in the registry, so it survives reboots and
is not affected by anything on the host.

**Getting the file into the guest.** The guest is on libvirt's `default` NAT
network, so the host is always `192.168.122.1` from inside Windows. On the host:

```bash
python -m http.server 8000 --directory ~/vfio-acpi/build/edid --bind 192.168.122.1
```

Two things that are not optional here. `--bind`, or the server also listens on
the LAN address. And an **absolute** `--directory`: it resolves against the
shell's cwd, and Python does not complain about a directory that does not exist
-- it just 404s everything, which looks like a firewall problem and is not one.
A 404 on `/` itself means the served directory is wrong or empty; a 404 on only
the filename means the directory is right and the name is off. Ctrl-C when done. Then in Windows, browse to
`http://192.168.122.1:8000/` and click the file, or:

```
curl.exe -o "%USERPROFILE%\Downloads\host-DP-1.bin" http://192.168.122.1:8000/host-DP-1.bin
```

(`curl.exe` with the extension -- bare `curl` in PowerShell is an alias for
`Invoke-WebRequest` and takes different arguments.) Check it arrived whole:

```
certutil -hashfile "%USERPROFILE%\Downloads\host-DP-1.bin" SHA256
```

| file | sha256 |
|---|---|
| `host-DP-1.bin` | `f6d15e39ffcd7082de17c73e7325bee99f21b75378f1c74a95fbcd6686552c8f` |
| `host-DP-2.bin` | `a4de9ec0c5d3432220d35c622182cdccd45f3093045288a83c208bfa5dcfc0a1` |

A truncated or text-mangled EDID is the kind of thing NVCP rejects with an
unhelpful error. If the download hangs instead, that is a host firewall rule on
`virbr0` -- the default network only explicitly permits DNS and DHCP to the host.

Then, in the guest:

1. **NVIDIA Control Panel -> Workstation -> View System Topology**
   (this page exists only on the workstation driver -- a GeForce has no
   Workstation section at all)
2. Click **EDID** next to the target connector -> **Load EDID**
3. Choose the file, target connector `DisplayPort (1)`, connector type
   DisplayPort -> apply
4. In Windows, make that display the **main display**. `GetDC(nullptr)` follows
   the primary, so an IDD display left as primary keeps the check firing no
   matter what the Quadro is doing.

**Undo:** same page, **Unload EDID**.

The EDID files are in `edid/`, read off this host's own connectors:

| file | monitor | modes |
|---|---|---|
| `edid/host-DP-1.bin` | BenQ ZOWIE XL LCD | 1920x1080 @ 60 / 100 / 120 / 144 / 240 |
| `edid/host-DP-2.bin` | HP LA2206 | 1920x1080 @ 60 |

Use the ZOWIE one -- a genuine 240 Hz panel is a more plausible thing to find on
this box than the generic blob most dummy plugs carry. Both files are 256 bytes
(base block + CTA extension), which the NVCP loader takes as-is; copy to `.txt`
if its file picker filters on extension.

Regenerate either of them while that monitor is plugged into the host:

```bash
cat /sys/class/drm/card1-DP-1/edid > edid/host-DP-1.bin
```

`stat` reports these as 0 bytes -- they are sysfs binary attributes. `cat` gets
the real 256. `card1` is the host RTX 4080 SUPER; check `/sys/class/drm/` for
which connectors are `connected` before copying.

**Verified 2026-09-08.** System Topology shows `DisplayPort (1) -- Connected:
BenQ ZOWIE XL LCD`, `EDID (File)`, `Usage Mode: WDDM`; Windows drives it at
1920x1080 @ 239.76 Hz (which is DTD 5 of the file, so the whole mode list came
through). DisplayPort accepted the override with **no** hotplug-detect load,
which is not guaranteed on every driver version -- if a future driver refuses,
that is the case a physical dummy plug still solves.

One tell, for the record: NVCP shows `EDID source: File` and NvAPI can read that
back. Nothing in VMAware looks at it, but it is the one thing this method has
that a plug would not.

---

## Checking state

```bash
./check.sh          # everything, no root, prints the fix for whatever is wrong
```

That is the one to reach for. It verifies the kernel and module vermagic, which
build is actually loaded, the taint bits, all six knobs, `kvm-stealth.service`,
the libvirt hook, the ananicy rule, core isolation and the running VM.

Narrower views, if you want them:

```bash
sudo ./root-step13-vm-tuning.sh status     # hook, ananicy, cpusets, preemption counters
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
