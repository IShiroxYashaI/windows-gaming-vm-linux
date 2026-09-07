#!/usr/bin/env bash
set -euo pipefail
BT=/usr/lib/modules/7.2.2-1-cachyos/build
SRC=~/vfio-acpi/build/cachy/cachyos-7.2.2-1
OUT=${1:-stock}
cd "$SRC"

echo "== seeding Module.symvers from distro build tree (avoids full vmlinux build) =="
cp -f "$BT/Module.symvers" .

echo "== modules_prepare =="
make LLVM=1 -j48 modules_prepare 2>&1 | tail -5

echo "== building arch/x86/kvm modules =="
make LLVM=1 -j48 M=arch/x86/kvm modules 2>&1 | tail -25

echo "== results =="
mkdir -p ~/vfio-acpi/build/kmod/$OUT
for m in arch/x86/kvm/kvm.ko arch/x86/kvm/kvm-amd.ko; do
  [ -f "$m" ] || { echo "MISSING: $m"; exit 1; }
  cp -f "$m" ~/vfio-acpi/build/kmod/$OUT/
done
ls -l ~/vfio-acpi/build/kmod/$OUT/
echo "== vermagic check (must equal running kernel's) =="
for m in ~/vfio-acpi/build/kmod/$OUT/*.ko; do
  printf '%-12s %s\n' "$(basename $m)" "$(modinfo -F vermagic $m)"
done
echo "running kvm_amd: $(modinfo -F vermagic kvm_amd)"
echo "BUILD_DONE_$OUT"
