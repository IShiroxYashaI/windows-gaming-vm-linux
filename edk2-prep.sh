#!/usr/bin/env bash
set -euo pipefail
SRC=/home/shiroyasha/vfio-acpi/build/AutoVirt/src/edk2-stable202605
PATCHF=/home/shiroyasha/vfio-acpi/build/AutoVirt/patches/EDK2/AMD-edk2-stable202605.patch
cd "$SRC"

uhex() {
  local bytes="$1"
  local v="$2"
  local width=$((bytes * 2))
  case "$v" in
    0x*|0X*) printf "0x%0${width}X" "$((v))" ;;
    *.*)     IFS='.' read -r a b _ <<< "$v"; b="${b:-0}"
             if (( bytes == 4 )); then printf "0x%0${width}X" "$(( (a << 16) | b ))"
             else                      printf "0x%0${width}X" "$(( (a << 48) | (b << 32) ))"; fi ;;
    [0-9]*)  printf "0x%0${width}X" "$v" ;;
    *)       printf "%-${bytes}s" "$v" | LC_ALL=C od -An -t x1 -v \
               | awk '{for(i=NF;i>=1;i--) printf $i} END{print ""}' | sed 's/^/0x/' ;;
  esac
}

BIOS_VENDOR="$(</sys/class/dmi/id/bios_vendor)"
BIOS_VERSION="$(</sys/class/dmi/id/bios_version)"
BIOS_DATE="$(</sys/class/dmi/id/bios_date)"
BIOS_REVISION="$(uhex 4 "$(</sys/class/dmi/id/bios_release)")"

F1=/home/shiroyasha/vfio-acpi/build/facp-fields.txt
F2=/home/shiroyasha/vfio-acpi/build/facp-extra.txt
# NOTE: values contain significant trailing spaces - must NOT be sourced as shell
OEMID="$(sed -n 's/^OEMID=//p' "$F1")"
OEM_TABLE_ID="$(sed -n 's/^OEM_TABLE_ID=//p' "$F1")"
CREATOR_ID="$(sed -n 's/^CREATOR_ID=//p' "$F1")"
OEM_REVISION_U32="$(sed -n 's/^OEM_REVISION_U32=//p' "$F2")"
CREATOR_REVISION_U32="$(sed -n 's/^CREATOR_REVISION_U32=//p' "$F2")"
[ ${#OEMID} -eq 6 ] || { echo "!! OEMID is ${#OEMID} chars, expected 6: [$OEMID]"; exit 1; }
[ ${#OEM_TABLE_ID} -eq 8 ] || { echo "!! OEM_TABLE_ID is ${#OEM_TABLE_ID} chars, expected 8"; exit 1; }
[ ${#CREATOR_ID} -eq 4 ] || { echo "!! CREATOR_ID is ${#CREATOR_ID} chars, expected 4"; exit 1; }
OEM_TABLE_HEX="$(uhex 8 "$OEM_TABLE_ID")"
CREATOR_HEX="$(uhex 4 "$CREATOR_ID")"
OEM_REV_HEX="$(uhex 4 "$OEM_REVISION_U32")"
CRE_REV_HEX="$(uhex 4 "$CREATOR_REVISION_U32")"

echo "[*] Derived values:"
printf '    BIOS_VENDOR=%s\n    BIOS_VERSION=%s\n    BIOS_DATE=%s\n    BIOS_REVISION=%s\n' \
  "$BIOS_VENDOR" "$BIOS_VERSION" "$BIOS_DATE" "$BIOS_REVISION"
printf '    OEMID="%s"  OEM_TABLE=%s  CREATOR=%s\n    OEM_REV=%s  CREATOR_REV=%s\n' \
  "$OEMID" "$OEM_TABLE_HEX" "$CREATOR_HEX" "$OEM_REV_HEX" "$CRE_REV_HEX"

echo "[*] Applying EDK2 patch..."
git apply --check "$PATCHF" && git apply "$PATCHF"
echo "    ok"

echo "[*] Verifying LPC relocation landed (must be 0x14):"
grep -n "PCI_LIB_ADDRESS (0, 0x14, 0, (Offset))" OvmfPkg/Include/IndustryStandard/Q35MchIch9.h

echo "[*] Stamping SMBIOS strings..."
sed -i \
  -e 's@VendStr = L"unknown";@VendStr = L"'"$BIOS_VENDOR"'";@' \
  -e 's@VersStr = L"unknown";@VersStr = L"'"$BIOS_VERSION"'";@' \
  -e 's@DateStr = L"02/02/2022";@DateStr = L"'"$BIOS_DATE"'";@' \
  OvmfPkg/SmbiosPlatformDxe/SmbiosPlatformDxe.c

echo "[*] Stamping firmware/ACPI PCDs..."
sed -E -i \
  -e 's@(PcdFirmwareVendor)\|L"EDK II"\|@\1|L"'"$BIOS_VENDOR"'"|@' \
  -e 's@(PcdFirmwareRevision)\|0x00010000\|@\1|'"$BIOS_REVISION"'|@' \
  -e 's@(PcdFirmwareVersionString)\|L""\|@\1|L"'"$BIOS_VERSION"'"|@' \
  -e 's@(PcdFirmwareReleaseDateString)\|L""\|@\1|L"'"$BIOS_DATE"'"|@' \
  -e 's@(PcdAcpiDefaultOemId)\|"INTEL "\|@\1|"'"$OEMID"'"|@' \
  -e 's@(PcdAcpiDefaultOemTableId)\|0x20202020324B4445\|@\1|'"$OEM_TABLE_HEX"'|@' \
  -e 's@(PcdAcpiDefaultOemRevision)\|0x00000002\|@\1|'"$OEM_REV_HEX"'|@' \
  -e 's@(PcdAcpiDefaultCreatorId)\|0x20202020\|@\1|'"$CREATOR_HEX"'|@' \
  -e 's@(PcdAcpiDefaultCreatorRevision)\|0x01000013\|@\1|'"$CRE_REV_HEX"'|@' \
  MdeModulePkg/MdeModulePkg.dec

echo "[*] Resulting PCD lines:"
grep -nE "PcdFirmwareVendor\||PcdFirmwareRevision\||PcdFirmwareVersionString\||PcdFirmwareReleaseDateString\||PcdAcpiDefaultOem|PcdAcpiDefaultCreator" MdeModulePkg/MdeModulePkg.dec | sed 's/^/    /'
echo "[*] SmbiosPlatformDxe strings:"
grep -nE "VendStr|VersStr|DateStr" OvmfPkg/SmbiosPlatformDxe/SmbiosPlatformDxe.c | head -5 | sed 's/^/    /'

echo "[*] Injecting host boot logo (BGRT)..."
cp /sys/firmware/acpi/bgrt/image MdeModulePkg/Logo/Logo.bmp
echo "    $(file -b MdeModulePkg/Logo/Logo.bmp)"
echo "[*] PREP COMPLETE"
