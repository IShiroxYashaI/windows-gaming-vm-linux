#!/usr/bin/env bash
set -eu
# SUPERSEDED by root-step13-vm-tuning.sh, which does this from the libvirt hook
# on every VM start and reverts it on shutdown. Kept because it is a handy
# one-shot, but it is runtime-only and must be re-run after every reboot.
#
# Reserve CCD3 (18-23,42-47) for the VM. QEMU lives in machine.slice, so it is unaffected.
HOST_CPUS="0-17,24-41"
for u in system.slice user.slice init.scope; do
  systemctl set-property --runtime "$u" AllowedCPUs="$HOST_CPUS" && echo "  $u -> $HOST_CPUS"
done
echo "[*] Verify:"
for u in system.slice user.slice init.scope; do
  printf '  %-14s %s\n' "$u" "$(systemctl show -p AllowedCPUs --value "$u")"
done
echo "[*] Runtime-only: reboot or 'systemctl set-property --runtime <unit> AllowedCPUs=' to undo."
