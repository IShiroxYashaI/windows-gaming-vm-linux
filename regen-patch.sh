#!/usr/bin/env bash
# Regenerate kvm-stealth.mypatch by diffing the working tree against pristine
# files extracted from the CachyOS 7.2.2-1 tarball.
set -euo pipefail
ROOT=/home/shiroyasha/vfio-acpi/build
SRC=$ROOT/cachy/cachyos-7.2.2-1
TAR=$ROOT/cachy/cachyos-7.2.2-1.tar.gz
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FILES="arch/x86/kvm/x86.c arch/x86/kvm/emulate.c arch/x86/kvm/svm/svm.c"

echo "== extracting pristine copies =="
for f in $FILES; do
    tar xzf "$TAR" -C "$TMP" "cachyos-7.2.2-1/$f"
done

OUT=$ROOT/kernel-patches/kvm-stealth.mypatch
: > "$OUT"
for f in $FILES; do
    diff -u "$TMP/cachyos-7.2.2-1/$f" "$SRC/$f" \
        | sed -e "1s|.*|--- a/$f|" -e "2s|.*|+++ b/$f|" >> "$OUT" || true
done

echo "== regenerated: $OUT =="
wc -l "$OUT"
echo "== knobs present in patch =="
grep -c 'stealth_svm_ud'            "$OUT" || true
grep -c 'stealth_hypercall_ud'      "$OUT" || true
grep -c 'stealth_no_hypercall_patch' "$OUT" || true
echo "== files touched =="
grep '^--- a/' "$OUT"
