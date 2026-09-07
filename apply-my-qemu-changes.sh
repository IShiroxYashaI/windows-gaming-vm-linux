#!/usr/bin/env bash
# Reproducible: pristine QEMU v11.0.3 -> AutoVirt AMD patch -> our anti-detection deltas.
set -eu
SRC=/home/shiroyasha/vfio-acpi/build/AutoVirt/src/v11.0.3
PATCHF=/home/shiroyasha/vfio-acpi/build/AutoVirt/patches/QEMU/AMD-v11.0.3.patch
F1=/home/shiroyasha/vfio-acpi/build/facp-fields.txt
cd "$SRC"

echo "[1] Reset to pristine v11.0.3"
git checkout . && git clean -fd >/dev/null 2>&1 || true

echo "[2] Apply AutoVirt AMD-v11.0.3.patch"
git apply "$PATCHF"

OEMID="$(sed -n 's/^OEMID=//p' "$F1")"
CREATOR_ID="$(sed -n 's/^CREATOR_ID=//p' "$F1")"
[ ${#OEMID} -eq 6 ] && [ ${#CREATOR_ID} -eq 4 ] || { echo "!! bad FADT field widths"; exit 1; }

python3 - "$OEMID" "$CREATOR_ID" <<'PYEOF'
import sys
OEMID, CREATOR = sys.argv[1], sys.argv[2]
def edit(path, subs):
    s = open(path, encoding="utf-8").read()
    for old, new, label in subs:
        n = s.count(old)
        assert n == 1, "%s: anchor %r matched %d times" % (path, label, n)
        s = s.replace(old, new)
        print("    + %s" % label)
    open(path, "w", encoding="utf-8").write(s)

# [3] SMI0 -> PDRC : kills ACPI_SIGNATURE + both FIRMWARE paths
edit("hw/i386/acpi-build.c", [(
 '            dev = aml_device("PCI0.SMI0");\n'
 '            aml_append(dev, aml_name_decl("_HID", aml_eisaid("PNP0A06")));\n'
 '            aml_append(dev, aml_name_decl("_UID", aml_string("SMI resources")));',
 '            dev = aml_device("PCI0.PDRC");\n'
 '            aml_append(dev, aml_name_decl("_HID", aml_eisaid("PNP0C02")));\n'
 '            aml_append(dev, aml_name_decl("_UID", aml_int(1)));',
 "SMI0 -> PDRC / PNP0C02 / _UID int")])

# [4] PHPR string _UID -> int : instance id would read ACPI\PNP0A06\PCI_HOTPLUG_RESOURCES
edit("hw/acpi/pcihp.c", [(
 '    aml_append(dev,\n'
 '               aml_name_decl("_UID", aml_string("PCI Hotplug resources")));',
 '    aml_append(dev, aml_name_decl("_UID", aml_int(1)));',
 "PHPR _UID -> int (removes HOTPLUG from instance id)")])

# [5] ACPI identity mirrors host FADT; [6] PM profile -> Workstation (host reports 3)
edit("include/hw/acpi/aml-build.h", [(
 '#define ACPI_BUILD_APPNAME6 "ALASKA"',
 '#define ACPI_BUILD_APPNAME6 "%s"' % OEMID, "APPNAME6 -> host OEMID")])
edit("hw/acpi/aml-build.c", [
 ('g_array_append_vals(array, "ACPI", 4);',
  'g_array_append_vals(array, "%s", 4);' % CREATOR, "Creator ID -> host"),
 ('build_append_int_noprefix(tbl, 1 /* Desktop */, 1);',
  'build_append_int_noprefix(tbl, 3 /* Workstation */, 1);', "PM profile -> Workstation")])

# [7] device models sized to the real 224/239 GB disks
edit("hw/ide/core.c", [
 ('"HL-DT-ST BD-RE WH16NS60"', '"ASUS DRW-24B1ST"', "ide cd model"),
 ('"Hitachi HMS360404D5CF00"', '"SanDisk Ultra microSDXC UHS-I"', "ide cfata model"),
 ('"Samsung SSD 980 500GB"', '"Samsung SSD 860 EVO 250GB"', "sata disk model")])
edit("hw/nvme/ctrl.c", [('"NVMe Ctrl"', '"Samsung SSD 970 EVO Plus 1TB"', "nvme model")])
PYEOF

echo "[8] Verify no detection strings survive in source"
for s in '"SMI resources"' '"GPE0 resources"' '"PCI Hotplug resources"' 'ALASKA'; do
  c=$(grep -rn -- "$s" hw/ include/ 2>/dev/null | wc -l)
  printf '    %-26s %s\n' "$s" "$c"
done
echo "APPLY COMPLETE"
