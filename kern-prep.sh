#!/usr/bin/env bash
# Fetch + prepare the kernel source tree matching the RUNNING kernel.
# Needs no editing after a kernel update -- see kver.sh.
set -euo pipefail
cd "$(dirname "$0")"
source ./kver.sh
kver_show

[ -d "$KBT" ] || {
    echo "!! distro build tree missing: $KBT"
    echo "   install the headers for $KREL first (e.g. linux-cachyos-headers)"
    exit 1; }

mkdir -p "$KROOT"
cd "$KROOT"

if [ ! -d "$KSRC" ]; then
    if [ ! -f "$KTAR" ]; then
        echo "== fetching $KTAG.tar.gz =="
        echo "   $KURL"
        curl -fL --progress-bar -o "$KTAR.part" "$KURL" || {
            rm -f "$KTAR.part"
            echo "!! download failed. Fetch it by hand into $KROOT/ and re-run:"
            echo "   $KURL"
            exit 1; }
        mv "$KTAR.part" "$KTAR"
    fi
    echo "== extracting =="
    tar xzf "$KTAR"
fi
cd "$KSRC"

echo "== version =="
grep -E '^(VERSION|PATCHLEVEL|SUBLEVEL|EXTRAVERSION)' Makefile | head -4
MKVER=$(make -s kernelversion 2>/dev/null || true)
if [ -n "$MKVER" ] && [ "$MKVER" != "$KBASE" ]; then
    echo "!! tarball is $MKVER but the running kernel is $KBASE -- wrong source tree"
    exit 1
fi

echo "== localversion (vermagic components, derived from $KREL) =="
echo "$KPKGREL"  > localversion.10-pkgrel
echo "$KPKGNAME" > localversion.20-pkgname
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
