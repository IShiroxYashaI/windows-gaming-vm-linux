#!/usr/bin/env bash
# build-lab.sh — one-time setup of the win11-lab sandbox.
#
# Frees the 256GB SSD (guest sdb), formats it as /mnt/vmlab, drops the golden
# 0/85 image onto it read-only, stacks a disposable overlay, and defines the
# win11-lab domain. Run once:
#
#     sudo bash /home/shiroyasha/vfio-acpi/build/build-lab.sh --yes-wipe-ssd
#
# DESTRUCTIVE: it ERASES the 256GB SSD (serial XXXXXXXXXXXXX, the old games
# disk). Everything on it is gone. The WD Green (Windows C:) is NOT touched.
set -euo pipefail

# ---- fixed facts about this machine ---------------------------------------
SSD_BYID=/dev/disk/by-id/ata-SSD_256GB_XXXXXXXXXXXXX   # the drive to wipe
GOLDEN_SRC=/mnt/backup/stealth_vfio/win11-clean-0of85-20260909.qcow2
MNT=/mnt/vmlab
GOLDEN=$MNT/win11-golden.qcow2
OVERLAY=$MNT/win11-lab.qcow2
NVRAM_SRC=/var/lib/libvirt/qemu/nvram/win11_VARS.fd
NVRAM_LAB=/var/lib/libvirt/qemu/nvram/win11-lab_VARS.fd
LAB_XML=/home/shiroyasha/vfio-acpi/build/libvirt/win11-lab.xml
WIN11_XML=/home/shiroyasha/vfio-acpi/build/libvirt/win11.xml
RESET_SRC=/home/shiroyasha/vfio-acpi/build/reset-lab.sh
OWNER=shiroyasha:shiroyasha
VIRSH="virsh -c qemu:///system"

die(){ echo "ERROR: $*" >&2; exit 1; }

[[ ${EUID:-$(id -u)} -eq 0 ]] || die "run me with sudo."
[[ "${1:-}" == "--yes-wipe-ssd" ]] || die "refusing: pass --yes-wipe-ssd to confirm ERASING $SSD_BYID"

# ---- safety guards --------------------------------------------------------
DEV=$(readlink -f "$SSD_BYID") || die "cannot resolve $SSD_BYID"
[[ -b "$DEV" ]]                || die "$DEV is not a block device"
SZ=$(blockdev --getsize64 "$DEV")
# 256 GB SSD ~ 256.06e9 bytes; guard against grabbing the 1TB backup or a 2TB nvme
[[ $SZ -gt 200000000000 && $SZ -lt 300000000000 ]] || die "size $SZ of $DEV is not ~256GB — wrong disk, aborting"
if findmnt -rno SOURCE | grep -q "^$DEV"; then die "$DEV or a partition of it is mounted — aborting"; fi
[[ -f "$GOLDEN_SRC" ]]         || die "golden image $GOLDEN_SRC not found"
[[ -f "$NVRAM_SRC" ]]          || die "win11 nvram $NVRAM_SRC not found"
[[ -f "$LAB_XML" ]]            || die "$LAB_XML not found"
$VIRSH domstate win11 2>/dev/null | grep -q "shut off" || die "win11 is not shut off — shut it down first"

echo ">> target confirmed: $DEV ($((SZ/1000/1000/1000)) GB), win11 is off. Proceeding."

# ---- 1. detach the SSD from the daily win11 definition --------------------
echo ">> [1/7] redefining win11 without the sdb disk"
$VIRSH define "$WIN11_XML"

# ---- 2. wipe + format the SSD --------------------------------------------
echo ">> [2/7] wiping and formatting $DEV as ext4 (label vmlab)"
wipefs -a "$DEV"
mkfs.ext4 -F -L vmlab "$DEV"

# ---- 3. mount at /mnt/vmlab + persist in fstab ---------------------------
echo ">> [3/7] mounting at $MNT and adding to /etc/fstab"
mkdir -p "$MNT"
UUID=$(blkid -s UUID -o value "$DEV") || die "no UUID after mkfs"
if ! grep -q "$UUID" /etc/fstab; then
  printf 'UUID=%s  %s  ext4  defaults,noatime,nofail  0 2\n' "$UUID" "$MNT" >> /etc/fstab
fi
mountpoint -q "$MNT" || mount "$MNT"
chown "$OWNER" "$MNT"

# ---- 4. golden image (read-only) -----------------------------------------
echo ">> [4/7] copying golden image onto the SSD (read-only)"
cp --sparse=always "$GOLDEN_SRC" "$GOLDEN"
chown "$OWNER" "$GOLDEN"
chmod 0444 "$GOLDEN"

# ---- 5. disposable overlay ------------------------------------------------
echo ">> [5/7] creating overlay on the golden"
qemu-img create -f qcow2 -F qcow2 -b "$GOLDEN" "$OVERLAY" >/dev/null
chown "$OWNER" "$OVERLAY"
cp "$RESET_SRC" "$MNT/reset-lab.sh"; chmod +x "$MNT/reset-lab.sh"; chown "$OWNER" "$MNT/reset-lab.sh"

# ---- 6. lab nvram (own copy of win11's UEFI state) -----------------------
echo ">> [6/7] giving the lab its own NVRAM"
cp "$NVRAM_SRC" "$NVRAM_LAB"
chown "$OWNER" "$NVRAM_LAB"; chmod 0600 "$NVRAM_LAB"

# ---- 7. define the lab domain --------------------------------------------
echo ">> [7/7] defining win11-lab"
$VIRSH define "$LAB_XML"

echo
echo "DONE. Layout:"
echo "  golden (RO): $GOLDEN"
echo "  overlay    : $OVERLAY"
$VIRSH list --all
echo
echo "Start the sandbox:   $VIRSH start win11-lab   (then run 'max-on' once Windows is up)"
echo "Reset to perfect:    $MNT/reset-lab.sh    (no sudo needed; or build/reset-lab.sh)"
echo "Your real VM:        $VIRSH start win11        (unchanged, minus the freed SSD)"
