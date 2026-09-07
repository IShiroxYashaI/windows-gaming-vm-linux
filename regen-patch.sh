#!/usr/bin/env bash
# Regenerate kvm-stealth.mypatch by diffing the working tree against pristine
# files extracted from the matching CachyOS tarball.
# Needs no editing after a kernel update -- see kver.sh.
set -euo pipefail
cd "$(dirname "$0")"
source ./kver.sh

[ -d "$KSRC" ] || { echo "!! source tree missing: $KSRC"; exit 1; }
[ -f "$KTAR" ] || { echo "!! tarball missing: $KTAR"; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FILES="arch/x86/kvm/x86.c arch/x86/kvm/emulate.c arch/x86/kvm/svm/svm.c"

echo "== extracting pristine copies from $KTAG =="
for f in $FILES; do
    tar xzf "$KTAR" -C "$TMP" "$KTAG/$f"
done

OUT=$KBUILD_ROOT/kernel-patches/kvm-stealth.mypatch
mkdir -p "$(dirname "$OUT")"
: > "$OUT"
for f in $FILES; do
    diff -u "$TMP/$KTAG/$f" "$KSRC/$f" \
        | sed -e "1s|.*|--- a/$f|" -e "2s|.*|+++ b/$f|" >> "$OUT" || true
done

echo "== regenerated: $OUT =="
wc -l "$OUT"
echo "== knobs present in patch =="
for k in stealth_svm_ud stealth_hypercall_ud stealth_no_hypercall_patch \
         stealth_vmcall_ud stealth_no_cpuid_intercept stealth_no_rdpru_intercept; do
    printf '   %-28s %s\n' "$k" "$(grep -c "$k" "$OUT" || true)"
done
echo "== files touched =="
grep '^--- a/' "$OUT"
