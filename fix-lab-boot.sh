#!/usr/bin/env bash
# fix-lab-boot.sh — make win11-lab bootable.
#
# The golden image is a perfect clone (valid GPT + intact FAT32 ESP + full
# Windows install), but Windows only installs its loader at
# \EFI\Microsoft\Boot\bootmgfw.efi and depends on a "Windows Boot Manager" NVRAM
# entry to find it, and Windows never installs the UEFI removable-media fallback.
#
# NOTE: the actual blocker in the first win11-lab boot was a stray <backingStore/>
# in the domain XML (the golden was never attached to the VM at all — see the
# "Gotcha" in VM-RUNBOOK.md), fixed separately by removing that element. This
# fallback loader is defense-in-depth: it makes the disk boot without depending on
# any NVRAM boot entry, which is generally useful for a cloned Windows disk.
#
# This installs the fallback loader \EFI\BOOT\BOOTX64.EFI (a copy of bootmgfw.efi)
# into the golden's ESP. After this, the plain "UEFI Samsung SSD ..." boot entry
# boots Windows directly, with no dependence on NVRAM boot entries — and it
# survives every reset-lab.sh because it lives in the golden.
#
# Run with win11-lab SHUT OFF:   sudo bash /home/shiroyasha/vfio-acpi/build/fix-lab-boot.sh
set -euo pipefail

GOLDEN=/mnt/vmlab/win11-golden.qcow2
OVERLAY=/mnt/vmlab/win11-lab.qcow2
NBD=/dev/nbd0
ESPMNT=/mnt/lab-esp
VIRSH="virsh -c qemu:///system"

die(){ echo "ERROR: $*" >&2; exit 1; }
[[ ${EUID:-$(id -u)} -eq 0 ]] || die "run me with sudo."
[[ -f "$GOLDEN" ]] || die "golden not found: $GOLDEN"
$VIRSH domstate win11-lab 2>/dev/null | grep -q "shut off" || die "win11-lab is not shut off — stop it first"
$VIRSH domstate win11     2>/dev/null | grep -q "shut off" || die "win11 is running — it may hold the disk; stop it"

modprobe nbd max_part=8

cleanup(){
  mountpoint -q "$ESPMNT" && umount "$ESPMNT" || true
  qemu-nbd -d "$NBD" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo ">> connecting golden to $NBD (temporarily writable)"
chmod u+w "$GOLDEN"
qemu-nbd -c "$NBD" "$GOLDEN"
partprobe "$NBD" 2>/dev/null || true
udevadm settle 2>/dev/null || true
# wait for the ESP partition node to appear
for i in $(seq 1 20); do [[ -b "${NBD}p1" ]] && break; udevadm settle 2>/dev/null || true; done
[[ -b "${NBD}p1" ]] || die "${NBD}p1 (the ESP) never appeared"

echo ">> mounting ESP (${NBD}p1)"
mkdir -p "$ESPMNT"
mount "${NBD}p1" "$ESPMNT"
[[ -f "$ESPMNT/EFI/Microsoft/Boot/bootmgfw.efi" ]] \
  || die "bootmgfw.efi not on ${NBD}p1 — is partition 1 really the ESP? (aborting, nothing changed)"

echo ">> installing fallback loader \\EFI\\BOOT\\BOOTX64.EFI"
mkdir -p "$ESPMNT/EFI/BOOT"
cp -f "$ESPMNT/EFI/Microsoft/Boot/bootmgfw.efi" "$ESPMNT/EFI/BOOT/BOOTX64.EFI"
sync
ls -l "$ESPMNT/EFI/BOOT/BOOTX64.EFI"

umount "$ESPMNT"
qemu-nbd -d "$NBD"
trap - EXIT
chmod 0444 "$GOLDEN"

echo ">> rebuilding the overlay on the patched golden"
rm -f "$OVERLAY"
qemu-img create -f qcow2 -F qcow2 -b "$GOLDEN" "$OVERLAY" >/dev/null
chown shiroyasha:shiroyasha "$OVERLAY"

echo
echo "DONE. Now start it:"
echo "  $VIRSH start win11-lab"
echo "It will boot straight into Windows via the disk entry. Then run 'max-on'."
