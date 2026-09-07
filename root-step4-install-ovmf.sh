#!/usr/bin/env bash
set -euo pipefail
FV=/home/shiroyasha/vfio-acpi/build/AutoVirt/src/edk2-stable202605/Build/OvmfX64/RELEASE_GCC/FV
VARS=/home/shiroyasha/vfio-acpi/build/OVMF_VARS.provisioned.fd
STAMP=$(date +%Y%m%d-%H%M%S)

RUNNING="$(virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -v '^$' || true)"
[ -z "$RUNNING" ] || { echo "!! domains still running: $RUNNING"; exit 1; }
[ -f "$FV/OVMF_CODE.fd" ] || { echo "!! built OVMF_CODE.fd missing"; exit 1; }
[ -f "$VARS" ] || { echo "!! provisioned VARS missing"; exit 1; }

echo "[*] Backing up current firmware in place..."
cp -a /opt/AutoVirt/firmware/OVMF_CODE.fd "/opt/AutoVirt/firmware/OVMF_CODE.fd.pre-edk2-$STAMP"
cp -a /opt/AutoVirt/firmware/OVMF_VARS.fd "/opt/AutoVirt/firmware/OVMF_VARS.fd.pre-edk2-$STAMP"

echo "[*] Installing new OVMF (matched to QEMU 11.0.3, LPC at 0x14)..."
install -m 0644 -o root -g root "$FV/OVMF_CODE.fd" /opt/AutoVirt/firmware/OVMF_CODE.fd
install -m 0644 -o root -g root "$VARS"            /opt/AutoVirt/firmware/OVMF_VARS.fd

echo "[*] Seeding domain NVRAM from provisioned template..."
mkdir -p /var/lib/libvirt/qemu/nvram
[ -f /var/lib/libvirt/qemu/nvram/win11_VARS.fd ] && \
  mv /var/lib/libvirt/qemu/nvram/win11_VARS.fd "/var/lib/libvirt/qemu/nvram/win11_VARS.fd.bak-$STAMP" || true
install -m 0600 "$VARS" /var/lib/libvirt/qemu/nvram/win11_VARS.fd

echo "[*] Result:"
ls -la /opt/AutoVirt/firmware/ /var/lib/libvirt/qemu/nvram/
echo "[*] smbios.bin must still be the Jul 10 ASUS one - check date above."
