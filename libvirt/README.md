# libvirt domain config

`win11.xml` — the **persistent** definition (`virsh dumpxml win11 --inactive`),
captured 2026-09-07 with VMAware at 0/85.

Nothing in this project modified the persistent config. The only domain changes
made during the KVM work were `virsh vcpupin ... --live` experiments (moving
guest core 3 to another CCD to test whether VMAware's TIMER measurement overhead
was sensitive to core placement — it isn't, see KVM-STEALTH.md), and those were
reverted. Kept here as a reference point so drift is visible later.

Restore with:

    virsh -c qemu:///system define libvirt/win11.xml

## Installer domain

`win11-install.xml` — the throwaway domain used for the 2026-09-09 fresh
reinstall. Identical GPU passthrough + `ramfb`/SPICE to `win11.xml`, but with the
LTSC ISO wired to the cdrom and `cdrom` first in the boot order:

    <boot dev='cdrom'/>
    <boot dev='hd'/>

WinPE renders on the SPICE primary, not the Quadro. Full step-by-step (wipe,
varstore reset, disk-letter map, driver) is in `../VM-RUNBOOK.md` →
"Reinstalling Windows from scratch". `win11-vbs-20260909.xml` is a VBS-enabled
variant kept for reference.

The persistent `win11.xml` boots `hd`-only with no ISO attached, so it comes up
straight into Windows with nothing to catch at boot.
