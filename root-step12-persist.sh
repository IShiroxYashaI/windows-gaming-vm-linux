#!/usr/bin/env bash
# Install/remove the boot-time patched-KVM swap.
#
#   sudo ./root-step12-persist.sh install
#   sudo ./root-step12-persist.sh remove
#   sudo ./root-step12-persist.sh status
#
# Nothing is written to /lib/modules and no distro file is modified, so a
# 'remove' (or just booting with the unit disabled) returns you to stock KVM.
set -uo pipefail
MODE=${1:-status}
SRC=/home/shiroyasha/vfio-acpi/build/kvm-stealth.service
DST=/etc/systemd/system/kvm-stealth.service

case "$MODE" in
  install)
    [ -f "$SRC" ] || { echo "!! $SRC missing"; exit 1; }
    install -m 0644 "$SRC" "$DST"
    systemctl daemon-reload
    systemctl enable kvm-stealth.service
    echo "== installed and enabled =="
    echo "It runs on the NEXT boot. To apply now without rebooting:"
    echo "   shut down all VMs, then: sudo systemctl start kvm-stealth.service"
    ;;
  remove)
    systemctl disable --now kvm-stealth.service 2>/dev/null
    rm -f "$DST"
    systemctl daemon-reload
    echo "== removed; next boot uses stock KVM =="
    ;;
  status)
    systemctl status kvm-stealth.service --no-pager 2>&1 | head -12
    echo
    echo "== loaded module srcversions =="
    for m in kvm kvm_amd; do
        printf "  %-8s %s\n" "$m" "$(cat /sys/module/$m/srcversion 2>/dev/null || echo '(not loaded)')"
    done
    echo "== knobs =="
    grep . /sys/module/kvm/parameters/stealth_* /sys/module/kvm_amd/parameters/stealth_* 2>/dev/null \
        | sed 's|/sys/module/|  |'
    ;;
  *) echo "usage: $0 [install|remove|status]"; exit 1 ;;
esac
