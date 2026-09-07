#!/usr/bin/env bash
# Build arch/x86/kvm out of tree against the RUNNING kernel's source.
# Needs no editing after a kernel update -- see kver.sh.
#   ./kern-build-kvm.sh [stock|patched]     (output dir under kmod/)
set -euo pipefail
cd "$(dirname "$0")"
source ./kver.sh
OUT=${1:-stock}
KMOD=$KBUILD_ROOT/kmod/$OUT
kver_show

[ -d "$KSRC" ] || { echo "!! source tree missing: $KSRC -- run ./kern-prep.sh first"; exit 1; }
[ -f "$KBT/Module.symvers" ] || { echo "!! $KBT/Module.symvers missing"; exit 1; }
cd "$KSRC"

J=$(nproc)
echo "== seeding Module.symvers from distro build tree (avoids full vmlinux build) =="
cp -f "$KBT/Module.symvers" .

echo "== modules_prepare =="
make LLVM=1 -j"$J" modules_prepare 2>&1 | tail -5

echo "== building arch/x86/kvm modules =="
make LLVM=1 -j"$J" M=arch/x86/kvm modules 2>&1 | tail -25

echo "== results =="
mkdir -p "$KMOD"
for m in arch/x86/kvm/kvm.ko arch/x86/kvm/kvm-amd.ko; do
  [ -f "$m" ] || { echo "MISSING: $m"; exit 1; }
  cp -f "$m" "$KMOD/"
done
ls -l "$KMOD/"

echo "== vermagic check (must equal the running kernel) =="
RC=0
for m in "$KMOD"/*.ko; do
  V=$(modinfo -F vermagic "$m")
  printf '%-12s %s\n' "$(basename "$m")" "$V"
  case "$V" in "$KREL"*) ;; *) echo "   !! does NOT match running $KREL"; RC=1 ;; esac
done
[ "$RC" = 0 ] || { echo "!! built modules will be rejected by insmod -- do NOT use insmod -f"; exit 1; }
echo "   all match $KREL"
echo "BUILD_DONE_$OUT"
