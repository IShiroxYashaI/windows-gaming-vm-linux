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

## Known quirk, unchanged on purpose

    <boot dev='cdrom'/>
    <boot dev='hd'/>
    <bootmenu enable='yes' timeout='30000'/>

CD-ROM is first in the boot order and the Win11 LTSC install ISO is still
attached as `sdc`, so any keypress at the 30-second boot menu lands you in
Windows Setup (the guest shows up as `minint-*` in the libvirt DHCP log rather
than `DESKTOP-*`). To stop that:

    virsh -c qemu:///system change-media win11 sdc --eject --config

Left as-is because it is the user's call, not a detection issue — VMAware does
not inspect optical drive strings.
