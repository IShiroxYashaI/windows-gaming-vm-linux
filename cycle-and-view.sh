#!/usr/bin/env bash
set -uo pipefail
V="virsh -c qemu:///system"

if $V domstate win11 | grep -q running; then
  echo "[*] Shutting down win11..."
  $V shutdown win11
  for i in $(seq 1 90); do
    $V domstate win11 2>/dev/null | grep -q "shut off" && break
    sleep 2
  done
fi

if ! $V domstate win11 | grep -q "shut off"; then
  echo "!! Guest did not shut down in 3 minutes. Force it with:  $V destroy win11"
  exit 1
fi

echo "[*] Starting win11 on QEMU 11.0.3..."
$V start win11
sleep 3
echo "[*] Opening SPICE viewer - you have a 30s boot menu window."
echo "    (press ESC in the viewer to enter the OVMF boot menu)"
exec spicy -h 127.0.0.1 -p 5900
