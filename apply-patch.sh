#!/usr/bin/env bash
# Apply kvm-stealth.mypatch to the prepared source tree.
# Needs no editing after a kernel update -- see kver.sh.  Idempotent.
set -euo pipefail
cd "$(dirname "$0")"
source ./kver.sh
P=$KBUILD_ROOT/kernel-patches/kvm-stealth.mypatch

[ -d "$KSRC" ] || { echo "!! no source tree: $KSRC -- run ./kern-prep.sh first"; exit 1; }
[ -f "$P" ]    || { echo "!! patch missing: $P"; exit 1; }

# Reverse dry-run succeeding means it is already in the tree.
if patch -p1 -d "$KSRC" --dry-run -R -s -f < "$P" >/dev/null 2>&1; then
    echo "== already applied to $KSRC =="
    exit 0
fi

if ! patch -p1 -d "$KSRC" --dry-run -s -f < "$P" >/dev/null 2>&1; then
    echo "!! the patch does not apply cleanly to $KSRC"
    echo "   the kernel moved under us. Re-add the six knobs by hand"
    echo "   (add-knob3.py .. add-knob6.py are idempotent editors), then run"
    echo "   ./regen-patch.sh to rebuild the patch against the new tarball."
    exit 1
fi

patch -p1 -d "$KSRC" < "$P"
echo "== applied to $KSRC =="
printf '   knob references in svm.c: %s\n' "$(grep -c stealth_ "$KSRC/arch/x86/kvm/svm/svm.c")"
