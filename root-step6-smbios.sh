#!/usr/bin/env bash
set -eu
NEW=/home/shiroyasha/vfio-acpi/build/smbios.fixed.bin
R="$(virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -v '^$' || true)"
[ -z "$R" ] || { echo "!! running: $R - shut down first"; exit 1; }
cp -a /opt/AutoVirt/firmware/smbios.bin "/opt/AutoVirt/firmware/smbios.bin.pre-topology-$(date +%Y%m%d-%H%M%S)"
install -m 0644 -o root -g root "$NEW" /opt/AutoVirt/firmware/smbios.bin
echo "[*] installed:"; ls -la /opt/AutoVirt/firmware/smbios.bin*
