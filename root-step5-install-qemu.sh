#!/usr/bin/env bash
set -eu
SRC=/home/shiroyasha/vfio-acpi/build/AutoVirt/src/v11.0.3
BIN=/opt/AutoVirt/emulator/bin/qemu-system-x86_64
RUNNING="$(virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -v '^$' || true)"
[ -z "$RUNNING" ] || { echo "!! still running: $RUNNING"; exit 1; }
echo "[*] Installing rebuilt QEMU 11.0.3 (adds PHPR fix)..."
ninja -C "$SRC/build" install >/tmp/qemu-install2.log 2>&1
"$BIN" --version | head -1
echo "[*] Detection strings in installed binary:"
for s in "SMI resources" "GPE0 resources" "PCI Hotplug resources" "ALASKA" "BXPC"; do
  printf '    %-24s %s\n' "$s" "$(strings -a "$BIN" | grep -c "$s" || true)"
done
echo "[*] Firmware dir (smbios.bin must stay Jul 10):"; ls -la /opt/AutoVirt/firmware/ | grep -v pre-edk2
