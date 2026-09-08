# Patched KVM for VM-detection hardening

Research notes for the `win11` VFIO guest on this host. Goal was to drive
[VMAware](https://github.com/kernelwernel/VMAware)'s detection score to zero
without touching TSC/RDTSC and without pretending kernel-level anticheat can be
defeated — the point was to find out which detections have a real mechanical
cause and which are architectural.

**Result: 8/85 → 0/85**, `VM brand: Unknown`, `VM confirmation: false`,
`VM likeliness: 0%`.

| stage | score | what changed |
|---|---|---|
| project start | 8/85 | before any of this (firmware/SMBIOS/ACPI work predates these notes) |
| unpatched control build | 3/85 | our own KVM build, no patches — proves the build itself is neutral |
| `patched` (4 knobs) | 1/85 | SVM_EXCEPTIONS + KVM_INTERCEPTION cleared |
| `patched` + `max-on` | **0/85** | TIMER cleared, INTERRUPT_SHADOW kept passing |

That table is KVM only. `GPU_CAPABILITIES` (weight 20) is a guest **display**
detection that rides alongside every row of it: with a `ramfb` or IddCx primary
display each score above reads one higher, and no module knob changes that.
It is cleared separately, by the EDID override -- see below.

---

## Host

- AMD Ryzen Threadripper 7960X (24C/48T, 4 CCDs, single NUMA node)
- ASUS Pro WS TRX50-SAGE WIFI
- CachyOS, kernel `7.2.2-1-cachyos`, built with `LLVM=1`
- Guest: Windows 11 IoT Enterprise LTSC 2024, 12 vCPUs pinned 1:1 to CCD 3
  (host `18-23` + SMT siblings `42-47`), `host-passthrough`, no `<hyperv>`
  enlightenments

## Build method

Only `arch/x86/kvm` is built, against CachyOS's own release tarball for the
*running* kernel, so `vermagic` matches and the modules can be hot-swapped with
`modprobe -r` / `insmod`. **Nothing is written to `/lib/modules`** and no distro
file is modified — booting without the systemd unit gives you stock KVM back.

```
kver.sh               sourced by the three below: derives every version-dependent
                      path from uname -r, so none of them need editing after a
                      kernel update. Override with KREL=<ver> to target another
kern-prep.sh          fetch the matching CachyOS tarball if absent, extract,
                      install /proc/config.gz, write localversion, olddefconfig
apply-patch.sh        apply kvm-stealth.mypatch; idempotent, and refuses rather
                      than half-patching if the anchors have moved
kern-build-kvm.sh     seed Module.symvers from the distro build tree so a full
                      vmlinux build isn't needed, then build M=arch/x86/kvm.
                      Fails if the result's vermagic != the running kernel
regen-patch.sh        regenerate kernel-patches/kvm-stealth.mypatch by diffing
                      the working tree against pristine tarball files
```

The `Module.symvers` seeding is the trick that makes this fast: without it,
`make modules` wants a full `vmlinux`.

The version derivation is worth one line of explanation: `uname -r` gives
`7.2.2-1-cachyos`, which splits into base `7.2.2`, pkgrel `-1` and pkgname
`-cachyos`. Those three reconstruct both the release tag `cachyos-7.2.2-1` (tarball,
URL and extracted directory all share it) and the `vermagic` the build will
produce. `kver.sh` checks the reconstruction equals `uname -r` before anything is
built, so a mismatch is caught up front rather than at `insmod`.

### Why the source tree matters

An earlier attempt used a generic `linux-7.2/` tree: version 7.2.**0**, built
with **gcc**, with an `olddefconfig` run that had silently dropped
`CONFIG_CACHY`. Loading those modules against a 7.2.2 LLVM kernel would have
produced silent struct-offset corruption — `vermagic` would still have matched.
Always build from the distro's own source for the exact running kernel, with the
live `.config` and the same toolchain.

### Safety evidence

Rather than asserting the swap is safe, each build was checked against the stock
one:

- identical undefined-symbol sets (463 for `kvm.ko`, 400 for `kvm-amd.ko`) — no
  new external dependencies
- identical module parameter lists apart from the added knobs
- exact `.data` / `.bss` / `.init.text` sizes (`.text` varies ~0.3% run to run
  from ThinLTO nondeterminism; the layout-sensitive sections do not)
- exact `vermagic` match
- taint `12288` = `TAINT_OOT_MODULE` + `TAINT_UNSIGNED_MODULE`. Bit 1
  (`TAINT_FORCED_MODULE`, value 2) is **absent**, which proves no `insmod -f`
  was needed
- an unpatched control build of the same source scored 3/85, unchanged from
  stock — so the score deltas come from the patches, not the build

---

## The knobs

Six module parameters, all default **off**. Four are safe to leave on
permanently; two are runtime-only and carry real trade-offs.

### `stealth_svm_ud` (kvm-amd, `0444`) — cleared SVM_EXCEPTIONS (35)

Intercepts `#GP` in the `EFER.SVME == 0` branch of `svm.c` so SVM instructions
executed at CPL3 fault the way bare metal does.

### `stealth_vmcall_ud` (kvm, `0644`) — cleared KVM_INTERCEPTION (150)

The actual fix for the KVM brand. VMAware executes `VMCALL` (`0F 01 C1`) from
user mode. On bare-metal AMD that is an invalid opcode → `#UD`. Under KVM the
`#UD` is intercepted and emulated, and the `Priv` check in `x86_emulate_insn()`
injects `#GP` instead, which Windows surfaces as `STATUS_ACCESS_VIOLATION` —
exactly the signal VMAware reads as "KVM".

The emulator already has the right flag for this (`PrivUD`, *"#UD instead of #GP
on CPL > 0"*); the `VMCALL` opcode entry simply doesn't set it:

```c
if ((ctxt->d & Priv) && ops->cpl(ctxt)) {
        if ((ctxt->d & PrivUD) ||
            (stealth_vmcall_ud && ctxt->execute == em_hypercall))
                rc = emulate_ud(ctxt);
        else
                rc = emulate_gp(ctxt, 0);
        goto done;
}
```

Gating on `ctxt->execute == em_hypercall` confines it to `VMCALL`; `VMMCALL`'s
table entry carries no `Priv` flag so it never reaches this branch.

### `stealth_hypercall_ud` (kvm, `0644`)

Injects `UD_VECTOR` in `kvm_emulate_hypercall()` after Xen/Hyper-V dispatch.
Required for the `VMMCALL` half of the same check.

### `stealth_no_hypercall_patch` (kvm, `0644`)

Forces the quirk-disabled `#UD` path in `emulator_fix_hypercall()`. **Contributed
nothing at CPL3** — that path is unreachable from user mode — but kept because
it is correct for ring-0. Documented here because three separate hypotheses were
spent on it before measurement showed the real cause was the `Priv` check above.

### `stealth_no_cpuid_intercept` (kvm-amd, `0644`) — cleared TIMER (100)

**Runtime-only. Off during guest boot.**

`INTERCEPT_CPUID` is an ordinary optional VMCB intercept bit. This is the key
AMD/Intel asymmetry: on VMX, `CPUID` is an unconditional VM exit and TIMER is
unwinnable; on SVM you can simply stop intercepting it, and `CPUID` retires
natively.

Synced from `svm_vcpu_run()` rather than `init_vmcb()` so it can be toggled
after Windows has booted and enumerated topology through the emulated path.
Guarded on `!is_guest_mode()` because `svm_set/clr_intercept()` write `vmcb01`
while `svm_is_intercept()` reads the active `vmcb02`, and the two would
disagree under nesting.

### `stealth_no_rdpru_intercept` (kvm-amd, `0644`)

**Runtime-only. Required whenever the CPUID knob is on.**

Once CPUID isn't intercepted the guest reads the raw host `Fn8000_0008_EBX[4]`
and believes RDPRU exists — but KVM still intercepts it and routes
`SVM_EXIT_RDPRU` to `kvm_handle_invalid_op()`, injecting `#UD`. VMAware's
INTERRUPT_SHADOW check dies there with `EXCEPTION_ILLEGAL_INSTRUCTION`
(`0xC000001D`).

Injecting a *different* exception does not help. That check does `mov ss, ax`
with `TF` set, creating an interrupt shadow that defers `#DB` by one
instruction, and its handler resumes **only** on `EXCEPTION_SINGLE_STEP`:

```c
vma_debug("INTERRUPT_SHADOW: Exception anomaly detected, "
          "hypervisor seems to be present with CPUID interception disabled");
```

So RDPRU must *retire without faulting* for the deferred `#DB` to land at the
expected IP. Clearing the intercept reproduces hardware exactly — RDPRU is
CPL3-executable on AMD by design (user mode reading APERF/MPERF without a
syscall). KVM intercepts it only to avoid leaking host counters.

Note that VMAware explicitly instruments for the CPUID trick — that debug string
names it directly, and INTERRUPT_SHADOW is weight **150** against TIMER's 100.
Disabling CPUID interception *without* also handling RDPRU is strictly worse
than leaving it alone.

---

## TIMER: what worked and what didn't

TIMER (weight 100) times `CPUID` against a cross-core software counter, with
8×`LFENCE` as the non-exiting reference, and flags a hypervisor at
`ratio >= 2.5`. It deliberately avoids TSC/RDTSC, so **none of the published
RDTSC patches (WCharacter, zhaodice, YungBinary) can move it.**

```
ratio = (M + E) / M      M = measurement overhead,  E = exit cost
```

| attempt | result |
|---|---|
| `mitigations=off` on the host | 14.66 → 8.26. **Real** — VMM 4545→2412 while nVMM held at ~300, so the exit genuinely halved rather than the clock scaling |
| cross-CCD vCPU pinning to inflate M | **No effect.** 292 → 270 |
| stop intercepting CPUID | 7.97 → **0.86**. VMM 2295 → 202 |

### Why the pinning idea failed

The theory was that moving the counter thread's core to another CCD would raise
M ~5× (Infinity Fabric vs intra-CCD L3) and drop the ratio without touching E.
It did nothing, and the reason is worth recording:

**M is not a latency — it's a count of writer iterations per reader round-trip
on a contended cache line.** Both the counter thread's tick rate and the
measurement window scale with the same interconnect latency, so it cancels. M is
structurally insensitive to core placement.

E didn't move either, for the complementary reason: during the exit the reader
isn't touching the line, so the writer runs uncontended at native speed
regardless of which CCD it's on.

The pin was verified genuinely in effect (`virsh vcpuinfo` showed vCPU 6 on host
CPU 12 / CCD 2 against vCPU 5 on host 44 / CCD 3) before concluding this.

### Why reducing E was never going to be enough

`vls` (Virtual VMLOAD/VMSAVE) is **absent on this CPU** — `v_vmsave_vmload` is
not in `/proc/cpuinfo` and `kvm_amd.vls` reads `0` — so every exit does an
explicit VMSAVE/VMLOAD of host state. With M ≈ 290, clearing the 2.5 threshold
needs the whole measured window under ~730, i.e. E ≤ ~438 cycles. A VMRUN/VMEXIT
round trip on Zen 4 without `vls` is comfortably over 1000. Halving the
mitigations tax got 14.66 → 8.26; there was no remaining factor of three in that
direction.

Removing the exit entirely was the only way, which is what the CPUID knob does.

### Ruled out

- **Hyper-V threshold loophole** (`threshold = 100.0` when
  `hyper_x() == HYPERV_HOST`) — trapped. Carries a
  `core::add(brand_enum::NULL_BRAND, 150)` penalty and requires a TPM
  measured-boot log we deliberately removed.
- **`kvm_amd` tuning** (`nested`, `lbrv`, `avic`, `tsc_scaling`) — already
  optimal; none of these are on the CPUID exit path.
- **Degenerate topology** — `get_mask()` returns `{}` and `timer()` returns
  `false` outright when `unique_cores_count < 2`, so
  `<topology cores='1' threads='12'/>` would abort TIMER before it measures.
  Rejected: Windows would treat all 12 logical CPUs as siblings of one core and
  schedule them at SMT priority, wrecking the thing this VM exists for.

---

## GPU_CAPABILITIES: the one that was never KVM's

After `max-on` cleared TIMER one detection was still standing, and no module
knob could ever have touched it -- it never enters the hypervisor.

`gpu_capabilities()`, weight 20 (`vma/vmaware.hpp:11518`):

```c
const HDC hdc = GetDC(nullptr);
if (!hdc) { return true; }
const int color_caps = GetDeviceCaps(hdc, COLORMGMTCAPS);
ReleaseDC(nullptr, hdc);
return !(color_caps & CM_GAMMA_RAMP) || color_caps == 0;
```

`GetDC(nullptr)` is the **primary display**. So despite the name this asks "does
the primary display driver expose a hardware gamma ramp?" -- nothing about the
GPU, its PCI IDs, or its passthrough. Two ways to fail it in a setup like this:

- `<model type='ramfb' heads='1' primary='yes'/>` in the domain: Windows binds
  the Microsoft Basic Display Adapter, which has no gamma ramp
- an IddCx indirect display driver (the IDD sample) left as primary: same
  result, IddCx does not expose hardware gamma either

The fix is to give Windows a real NVIDIA WDDM head and make it primary. The
usual answer is a dummy plug. The better one on a Quadro is the workstation
driver's own **EDID override** -- load a real monitor's EDID onto a connector
and the driver synthesises the connection with nothing attached. Procedure and
the EDID files: [[VM-RUNBOOK]].

Keep `ramfb` in the domain as a recovery path for when the NVIDIA driver is not
up yet, just not as `primary`.

Confirmed 2026-09-08: with the EDID loaded and the synthesised display set as
primary, `GPU_CAPABILITIES` clears and the score is **0/85**.

Worth stating plainly because it cost time to see: this is a *guest display
stack* problem wearing a GPU's name. Nothing in KVM, QEMU, the firmware or the
ACPI tables could have moved it.

---

## Trade-offs of `max-on`

The two intercept knobs are not free, and this is why they are runtime-toggleable
and off by default:

- The guest reads **raw host CPUID** — a 24C/48T package while Windows uses the
  12 logical CPUs it cached at boot, plus **every feature KVM masks because it
  cannot virtualize it**. RDPRU was one such landmine and is handled; others may
  exist and would surface as `#UD` in whatever software feature-detects them.
  This affects all guest software, not just detection tools.
- RDPRU passthrough lets the guest read the **host core's real MPERF/APERF**.
  That is a genuine host-state leak into the guest.
- VMAware's THREAD_MISMATCH (weight 45) was checked and does **not** newly trip:
  it bails at `!model_expects_smt && is_smt_active()` before comparing counts,
  and none of its inputs change (`model_name` is the brand string, already raw;
  `actual` comes from the OS thread count, not CPUID).

Leave `max-on` off for normal use. Turn it on for a measurement run.

---

## Usage

```bash
# one-time, per host boot (or install the systemd unit below)
sudo ./root-step10-kvm-swap.sh patched      # 4 safe knobs → 1/85

# after Windows is up, for a 0/85 run
sudo ./root-step10-kvm-swap.sh max-on
sudo ./root-step10-kvm-swap.sh max-off      # back to 1/85, takes effect
                                            # on the next VM entry

sudo ./root-step10-kvm-swap.sh restore      # back to distro modules
```

The two groups have **opposite** preconditions, which is worth internalising:

| mode | VM state required | why |
|---|---|---|
| `stock`, `patched-off`, `patched`, `restore` | all VMs **down** | the `.ko` files can't be unloaded while `/dev/kvm` is open |
| `max-on`, `max-off` | guest **up** | they only write sysfs on already-loaded modules, and the guest must have enumerated topology through the emulated CPUID path before the CPUID knob goes on |

The script enforces this: `max-on`/`max-off` are handled *before* the
"no VM running" guard and the `modprobe -r`, and `exit 0` immediately. An earlier
version had them inside the main `case`, below both — so `max-on` on a running
guest hit the guard and refused. It never got as far as the unload (and couldn't
have succeeded at it, since live QEMU holds `/dev/kvm`), but the error was
misleading. Fixed 2026-09-07.

### Persistence

```bash
sudo ./root-step12-persist.sh install       # enable at boot, before libvirtd
sudo ./root-step12-persist.sh status
sudo ./root-step12-persist.sh remove
```

The unit runs `patched` only — never `max-on`, because the guest must enumerate
topology through the emulated CPUID path while it boots.

**Installed and verified 2026-09-07**: `systemctl start` on a shut-down guest
produced `active (exited)`, `status=0/SUCCESS`, patched srcversions loaded, four
knobs on and the two intercept knobs correctly off. That exercised a real
unload/reload cycle including the `irqbypass` / `ccp` dependency handling.

Ordering note: `libvirtd.socket` is enabled on this host, and
`Before=libvirtd.service` does **not** order against the socket — socket
activation can start libvirtd before `multi-user.target`, open `/dev/kvm`, and
make the swap fail. It fails *safely* (the script restores the distro modules)
but you would boot unpatched without noticing. The unit therefore orders against
both the `.service` and `.socket` units of the monolithic and modular daemons;
systemd ignores ordering against units that don't exist.

### `mitigations=off`

`root-step11-boot-entry.sh add` creates a **separate** systemd-boot entry
(`sort-key zz-vmlatency`) that never touches the existing one. It halves the
VM-exit cost on Zen 4 by disabling SRSO Safe RET, TSA buffer clearing,
spectre_v2 eIBRS/STIBP and the VMSCAPE IBPB. Worth keeping for latency in its
own right, though with the CPUID knob it no longer matters for the score.

These are real speculative-execution mitigations. Fine on a single-user gaming
box; not something to do on a machine running untrusted workloads.

---

## Notes for later

- `THREAD_MISMATCH` debug reports *"CPU normally runs under SMT, but SMT was
  fully disabled on BIOS"* despite `cores='6' threads='2'`. Not a detection —
  the check passes — but it suggests `topoext` isn't landing as intended.
- The QEMU `KVM_CAP_DISABLE_QUIRKS2` hunk and `QUIRKDBG` instrumentation in
  `AutoVirt/src/v11.0.3/target/i386/kvm/kvm.c` were proven to do nothing and
  **have been removed** from the source (backup:
  `kvm.c.pre-quirk-revert.bak`). The running binary still contains them until
  QEMU is rebuilt — the only symptom is two stray `error_report` lines per VM
  start, so the rebuild is cosmetic and has not been done.
- VMAware's stubs are `const unsigned char[]` in read-only `.text`, so they
  can't be patched in place from the guest side.

---

## See also

[[VM-RUNBOOK]] — the short operational card: what to run when you restart the
VM, after a host reboot, or after a kernel update.

[[HOST-TUNING]] — frametime, latency and maintenance work on the same VM:
core isolation, the ananicy `Heavy_CPU` fix, IRQ affinity, huge pages, and the
libvirt hook that resets the max-* intercept knobs on domain start. None of it
changes the detection score; all of it changes how the VM actually feels.
