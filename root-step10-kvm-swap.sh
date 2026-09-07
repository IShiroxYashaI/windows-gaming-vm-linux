#!/usr/bin/env bash
# Hot-swap the KVM modules.  Usage:  sudo ./root-step10-kvm-swap.sh [stock|patched-off|patched|max-on|max-off|restore]
#   stock       - our rebuild of UNPATCHED source (proves build+load path is sound)
#   patched-off - patched build, both knobs at their default 0 (proves defaults are inert)
#   patched     - patched build, the four safe knobs on            (VMAware 1/85)
#   max-on      - also clear the CPUID+RDPRU intercepts, VM RUNNING (VMAware 0/85)
#   max-off     - undo max-on; takes effect on the next VM entry
#   restore     - back to the distro modules from /lib/modules
#
# Nothing is ever written to /lib/modules; a reboot always restores stock.
# NB: insmod does not resolve dependencies, and `modprobe -r` drops now-unused
# ones, so ccp/irqbypass are re-loaded explicitly before our modules go in.
set -uo pipefail
MODE=${1:-restore}
K=/home/shiroyasha/vfio-acpi/build/kmod

fail_restore() {
    echo "!! insmod failed - restoring distro modules"
    modprobe -r kvm_amd kvm 2>/dev/null
    modprobe kvm_amd && echo "   distro modules restored" || echo "   !! RESTORE FAILED - reboot to recover"
    exit 1
}

ensure_deps() {
    echo "== ensuring kvm-amd dependencies are loaded (kvm-amd depends on: kvm,ccp) =="
    for d in irqbypass ccp; do
        if lsmod | grep -q "^$d "; then
            echo "   $d already loaded"
        else
            modprobe "$d" && echo "   $d loaded" || { echo "!! could not load $d"; fail_restore; }
        fi
    done
}

# max-on/max-off only poke sysfs on the already-loaded modules, so they must run
# BEFORE the guard and the unload below. They also invert the usual precondition:
# a module swap needs every VM down, whereas these are meant to be flipped while
# the guest is up -- Windows has to enumerate topology through the emulated CPUID
# path first, so turning them on before it boots is the one thing to avoid.
if [ "$MODE" = max-on ] || [ "$MODE" = max-off ]; then
    # Toggle the two intercept knobs that clear VMAware's TIMER, on an already
    # loaded 'patched' build. Runtime-only on purpose: the guest must enumerate
    # topology through the emulated CPUID path while it boots, so these go on
    # AFTER Windows is up, never via insmod.
    #
    # Cost while on: the guest sees raw host CPUID (24C/48T, plus every feature
    # KVM masks) and reads the host core's MPERF/APERF through RDPRU. Guest
    # software that feature-detects can trip on a masked feature; RDPRU was one
    # such landmine and is handled, others may exist.
    [ -e /sys/module/kvm_amd/parameters/stealth_no_cpuid_intercept ] || {
        echo "!! patched kvm-amd not loaded; run '$0 patched' first"; exit 1; }
    [ "$MODE" = max-on ] && V=1 || V=0
    # RDPRU first when enabling, last when disabling: never leave a window where
    # the guest sees the CPUID feature bit while RDPRU still takes a #UD.
    if [ "$V" = 1 ]; then ORDER="rdpru cpuid"; else ORDER="cpuid rdpru"; fi
    for k in $ORDER; do
        echo $V > /sys/module/kvm_amd/parameters/stealth_no_${k}_intercept
    done
    echo "== max-stealth knobs set to $V =="
    grep . /sys/module/kvm_amd/parameters/stealth_no_*_intercept
    exit 0
fi

echo "== checking no VM is running =="
RUNNING=$(virsh -c qemu:///system list --state-running --name 2>/dev/null | grep -v '^$' || true)
if [ -n "$RUNNING" ]; then echo "!! VM(s) still running: $RUNNING -- shut down first"; exit 1; fi
echo "   ok, none running"

echo "== unloading current kvm modules =="
modprobe -r kvm_amd kvm || { echo "!! unload failed (is something holding /dev/kvm?)"; lsof /dev/kvm 2>/dev/null; exit 1; }
echo "   unloaded"

case "$MODE" in
  restore)
    modprobe kvm_amd || { echo "!! could not load distro modules - REBOOT"; exit 1; }
    echo "== restored distro modules =="
    ;;
  stock)
    ensure_deps
    insmod $K/stock/kvm.ko                           || fail_restore
    insmod $K/stock/kvm-amd.ko                       || fail_restore
    echo "== loaded OUR build, UNPATCHED (control) =="
    ;;
  patched-off)
    ensure_deps
    insmod $K/patched/kvm.ko                         || fail_restore
    insmod $K/patched/kvm-amd.ko                     || fail_restore
    echo "== loaded PATCHED build, knobs at default OFF =="
    ;;
  patched)
    ensure_deps
    insmod $K/patched/kvm.ko stealth_hypercall_ud=1 stealth_no_hypercall_patch=1 stealth_vmcall_ud=1 || fail_restore
    insmod $K/patched/kvm-amd.ko stealth_svm_ud=1    || fail_restore
    echo "== loaded PATCHED build, knobs ON =="
    ;;
  *) echo "usage: $0 [stock|patched-off|patched|max-on|max-off|restore]"; exit 1 ;;
esac

echo
echo "== status =="
lsmod | grep -E '^(kvm|ccp|irqbypass)'
echo "srcversion=$(cat /sys/module/kvm/srcversion 2>/dev/null)"
for p in /sys/module/kvm/parameters/stealth_hypercall_ud /sys/module/kvm/parameters/stealth_no_hypercall_patch /sys/module/kvm/parameters/stealth_vmcall_ud /sys/module/kvm_amd/parameters/stealth_svm_ud; do
    [ -e "$p" ] && echo "  $(basename $p) = $(cat $p)"
done
[ -e /dev/kvm ] && echo "/dev/kvm present" || echo "!! /dev/kvm MISSING"
echo "SWAP_DONE_$MODE"
