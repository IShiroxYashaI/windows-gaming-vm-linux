#!/usr/bin/env bash
set -euo pipefail
FV=/home/shiroyasha/vfio-acpi/build/AutoVirt/src/edk2-stable202605/Build/OvmfX64/RELEASE_GCC/FV
OUT=/home/shiroyasha/vfio-acpi/build/OVMF_VARS.provisioned.fd
EFI_GLOBAL_VARIABLE=8be4df61-93ca-11d2-aa0d-00e098032b8c
EFI_IMAGE_SECURITY_DATABASE_GUID=d719b2cb-3d3a-4596-a3bc-dad00e67656f
keys=( "PK:$EFI_GLOBAL_VARIABLE" "KEK:$EFI_GLOBAL_VARIABLE"
       "db:$EFI_IMAGE_SECURITY_DATABASE_GUID" "dbx:$EFI_IMAGE_SECURITY_DATABASE_GUID"
       "PKDefault:$EFI_GLOBAL_VARIABLE" "KEKDefault:$EFI_GLOBAL_VARIABLE"
       "dbDefault:$EFI_GLOBAL_VARIABLE" "dbxDefault:$EFI_GLOBAL_VARIABLE" )
J=$(mktemp); sep=""
{
  printf '{\n    "version": 2,\n    "variables": [\n'
  for entry in "${keys[@]}"; do
    IFS=: read -r name guid <<< "$entry"
    path="/sys/firmware/efi/efivars/${name}-${guid}"
    [[ -f "$path" ]] || { echo "    (skip $name - not present)" >&2; continue; }
    full_hex=$(hexdump -ve '1/1 "%.2x"' "$path" 2>/dev/null) || continue
    attr=$(printf '%d' "0x${full_hex:6:2}${full_hex:4:2}${full_hex:2:2}${full_hex:0:2}")
    printf '%s        { "name": "%s", "guid": "%s", "attr": %d, "data": "%s" }' \
        "$sep" "$name" "$guid" "$attr" "${full_hex:8}"
    echo "    + $name (${#full_hex} hex chars)" >&2
    sep=$',\n'
  done
  printf '\n    ]\n}\n'
} > "$J"
virt-fw-vars --input "$FV/OVMF_VARS.fd" --output "$OUT" --secure-boot --set-json "$J"
rm -f "$J"
echo "[*] wrote $OUT"; ls -la "$OUT"
