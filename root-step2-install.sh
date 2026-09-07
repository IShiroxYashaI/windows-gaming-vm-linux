#!/usr/bin/env bash
set -euo pipefail

SRC=/home/shiroyasha/vfio-acpi/build/AutoVirt/src/v11.0.3
BIN=/opt/AutoVirt/emulator/bin/qemu-system-x86_64

if ! virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -qx ""; then :; fi
RUNNING="$(virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -v '^$' || true)"
if [ -n "$RUNNING" ]; then
  echo "!! REFUSING TO INSTALL - these domains are still running:"
  echo "$RUNNING" | sed 's/^/     /'
  echo "   Shut the guest down first:  virsh -c qemu:///system shutdown win11"
  exit 1
fi

if [ ! -d /opt/AutoVirt.11.0.0-backup ]; then
  echo "!! REFUSING - /opt/AutoVirt.11.0.0-backup missing."
  exit 1
fi

echo "[*] Installing QEMU 11.0.3 to /opt/AutoVirt/emulator ..."
ninja -C "$SRC/build" install >/tmp/qemu-install.log 2>&1
echo "    done."

echo "[*] Verifying installed binary:"
"$BIN" --version | head -1

echo "[*] ACPI leak check on INSTALLED binary:"
for s in "SMI resources" "GPE0 resources" "ALASKA" "BXPC"; do
  printf '    %-16s %s\n' "$s" "$(strings -a "$BIN" | grep -c "$s" || true)"
done
echo "[*] Identity strings present:"
strings -a "$BIN" | grep -E '^AMD   $|^A M I   $|^AMI $' | sort -u | sed 's/^/    /'

echo "[*] Firmware dir untouched (smbios.bin must still be the ASUS one):"
ls -la /opt/AutoVirt/firmware/
