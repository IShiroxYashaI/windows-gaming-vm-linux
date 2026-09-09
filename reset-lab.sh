#!/usr/bin/env bash
# reset-lab.sh — throw away the win11-lab overlay and recreate it fresh on the
# read-only golden image, returning the lab VM to the perfect 0/85 Atlas state.
# Run as root (files live under /mnt/vmlab, owned by root; virsh is qemu:///system).
set -euo pipefail

GOLDEN=/mnt/vmlab/win11-golden.qcow2
OVERLAY=/mnt/vmlab/win11-lab.qcow2

if [[ ! -f "$GOLDEN" ]]; then
  echo "ERROR: golden image not found at $GOLDEN" >&2
  exit 1
fi

if virsh -c qemu:///system domstate win11-lab 2>/dev/null | grep -q running; then
  echo "win11-lab is running — shutting it down (destroy) before reset."
  virsh -c qemu:///system destroy win11-lab
fi

rm -f "$OVERLAY"
qemu-img create -f qcow2 -F qcow2 -b "$GOLDEN" "$OVERLAY" >/dev/null
chown root:root "$OVERLAY"

echo "Lab reset to golden ($(date '+%Y-%m-%d %H:%M'))."
echo "Start it with:  virsh -c qemu:///system start win11-lab   (then run max-on once Windows is up)"
