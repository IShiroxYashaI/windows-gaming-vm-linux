#!/usr/bin/env bash
set -euo pipefail

OUT=/home/shiroyasha/vfio-acpi/build/facp-fields.txt
T=/sys/firmware/acpi/tables/FACP

echo "[*] Backing up working 11.0.0 emulator..."
if [ -e /opt/AutoVirt.11.0.0-backup ]; then
  echo "    /opt/AutoVirt.11.0.0-backup already exists - leaving it alone."
else
  cp -a /opt/AutoVirt /opt/AutoVirt.11.0.0-backup
  echo "    -> /opt/AutoVirt.11.0.0-backup"
fi

echo "[*] Reading host FADT identity fields..."
{
  printf 'OEMID=%s\n'        "$(LC_ALL=C dd if=$T bs=1 skip=10 count=6 status=none | tr '\0' ' ')"
  printf 'OEM_TABLE_ID=%s\n' "$(LC_ALL=C dd if=$T bs=1 skip=16 count=8 status=none | tr '\0' ' ')"
  printf 'CREATOR_ID=%s\n'   "$(LC_ALL=C dd if=$T bs=1 skip=28 count=4 status=none | tr '\0' ' ')"
  printf 'PM_PROFILE=%s\n'   "$(LC_ALL=C dd if=$T bs=1 skip=45 count=1 status=none | od -An -tu1 | tr -d ' ')"
} > "$OUT"

chown shiroyasha:shiroyasha "$OUT"
echo "[*] Wrote $OUT:"
cat -A "$OUT"
