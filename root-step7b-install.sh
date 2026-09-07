#!/usr/bin/env bash
set -eu
SRC=/home/shiroyasha/vfio-acpi/build/AutoVirt/src/v11.0.3
BIN=/opt/AutoVirt/emulator/bin/qemu-system-x86_64
R="$(virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -v '^$' || true)"
[ -z "$R" ] || { echo "!! running: $R"; exit 1; }
ninja -C "$SRC/build" install >/tmp/qi.log 2>&1
chown shiroyasha:shiroyasha "$SRC/build/.ninja_deps" "$SRC/build/meson-logs/install-log.txt" 2>/dev/null || true
"$BIN" --version | head -1; ls -la "$BIN"
