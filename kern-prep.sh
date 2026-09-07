#!/usr/bin/env bash
set -euo pipefail
BT=/usr/lib/modules/7.2.2-1-cachyos/build
ROOT=~/vfio-acpi/build/cachy
SRC=$ROOT/cachyos-7.2.2-1

cd "$ROOT"
if [ ! -d "$SRC" ]; then
  echo "== extracting =="
  tar xzf cachyos-7.2.2-1.tar.gz
fi
cd "$SRC"

echo "== version =="
grep -E '^(VERSION|PATCHLEVEL|SUBLEVEL|EXTRAVERSION)' Makefile | head -4

echo "== localversion (vermagic components) =="
echo "-1"       > localversion.10-pkgrel
echo "-cachyos" > localversion.20-pkgname
cat localversion.10-pkgrel localversion.20-pkgname

echo "== install running config =="
zcat /proc/config.gz > .config
cp .config .config.running

echo "== olddefconfig (LLVM=1) =="
make LLVM=1 olddefconfig >/dev/null

echo "== config drift after olddefconfig =="
diff <(grep -v '^#' .config.running | sort) <(grep -v '^#' .config | sort) > /tmp/drift.txt 2>&1 || true
echo "differing lines: $(wc -l < /tmp/drift.txt)"
cat /tmp/drift.txt
echo "PREP_DONE"
