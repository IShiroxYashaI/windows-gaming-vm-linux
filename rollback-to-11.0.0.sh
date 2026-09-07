#!/usr/bin/env bash
set -euo pipefail
[ -d /opt/AutoVirt.11.0.0-backup ] || { echo "!! backup missing"; exit 1; }
if virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -q .; then
  echo "!! a domain is running; shut it down first"; exit 1
fi
echo "[*] Restoring working QEMU 11.0.0..."
rm -rf /opt/AutoVirt.broken-11.0.3
mv /opt/AutoVirt /opt/AutoVirt.broken-11.0.3
cp -a /opt/AutoVirt.11.0.0-backup /opt/AutoVirt
/opt/AutoVirt/emulator/bin/qemu-system-x86_64 --version | head -1
echo "[*] Restored. smbios.bin:"; ls -la /opt/AutoVirt/firmware/smbios.bin
