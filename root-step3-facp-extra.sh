#!/usr/bin/env bash
set -euo pipefail
T=/sys/firmware/acpi/tables/FACP
OUT=/home/shiroyasha/vfio-acpi/build/facp-extra.txt
{
  printf 'OEM_REVISION_U32=%s\n'     "$(LC_ALL=C od -An -t u4 -j 24 -N4 "$T" | tr -d ' ')"
  printf 'CREATOR_REVISION_U32=%s\n' "$(LC_ALL=C od -An -t u4 -j 32 -N4 "$T" | tr -d ' ')"
} > "$OUT"
chown shiroyasha:shiroyasha "$OUT"
echo "[*] Wrote $OUT:"; cat "$OUT"
