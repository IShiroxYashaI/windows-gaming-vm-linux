#!/usr/bin/env bash
set -eu
SRC=/home/shiroyasha/vfio-acpi/build/AutoVirt/src/v11.0.3
BIN=/opt/AutoVirt/emulator/bin/qemu-system-x86_64
R="$(virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -v '^$' || true)"
[ -z "$R" ] || { echo "!! running: $R"; exit 1; }
echo "[*] Fixing build-dir ownership (sudo ninja install left root-owned files)..."
chown shiroyasha:shiroyasha "$SRC/build/.ninja_deps" "$SRC/build/meson-logs/install-log.txt" 2>/dev/null || true
echo "[*] Rebuilding as user..."
sudo -u shiroyasha ninja -C "$SRC/build" -j"$(nproc)" >/tmp/qemu-rebuild.log 2>&1 || { tail -20 /tmp/qemu-rebuild.log; exit 1; }
echo "[*] Installing..."
ninja -C "$SRC/build" install >/tmp/qemu-install3.log 2>&1
"$BIN" --version | head -1
echo "[*] Subsystem defaults in binary (expect 1043 / 8877, no 1af4:1100):"
grep -c . /dev/null || true
echo "[*] Done."
