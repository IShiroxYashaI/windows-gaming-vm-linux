#!/usr/bin/env bash
# Host-side tuning for the win11 VFIO VM.  Usage:
#   sudo ./root-step13-vm-tuning.sh [install|remove|status|test|apply-now|revert-now]
#
#   install     install the libvirt hook + ananicy override (takes effect next VM start)
#   remove      undo install, restoring any files that were there before
#   status      show what is currently in effect
#   test        exercise the hook logic without libvirt (safe, no VM needed)
#   apply-now   do what the hook's started/begin does, for an ALREADY-RUNNING VM
#   revert-now  give all cores back to the host without stopping the VM
#
# Nothing here survives a host reboot by itself except the two installed files;
# the cpuset changes are --runtime on purpose, so a bad state self-heals.
set -uo pipefail
MODE=${1:-status}
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$HERE
HOOK=/etc/libvirt/hooks/qemu
ANA_DST=/etc/ananicy.d/99-local

VM_CPUS="18-23,42-47"
HOST_CPUS="0-17,24-41"
ALL_CPUS="0-47"
SLICES="system.slice user.slice init.scope"

# Find the win11 QEMU pid. Matching on comm and then verifying cmdline is
# deliberate: `pgrep -f guest=win11` also matches any shell whose command line
# happens to contain that string, including the one running this script.
vm_pid() {
    local p
    for p in $(pgrep -x qemu-system-x86 2>/dev/null) $(pgrep -x qemu-system-x86_64 2>/dev/null); do
        if tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null | grep -q 'guest=win11'; then
            echo "$p"; return 0
        fi
    done
    return 1
}

need_root() { [ "$(id -u)" = 0 ] || { echo "!! run me with sudo"; exit 1; }; }

libvirt_unit() {
    for u in virtqemud libvirtd; do
        systemctl is-active --quiet "$u" && { echo "$u"; return; }
    done
    echo ""
}

set_cpus() {
    local s
    for s in $SLICES; do
        systemctl set-property --runtime "$s" AllowedCPUs="$1" \
            && echo "   $s -> $1" \
            || echo "   !! $s rejected $1"
    done
}

case "$MODE" in

install)
    need_root
    [ -f "$SRC/hooks/qemu" ] || { echo "!! $SRC/hooks/qemu missing"; exit 1; }

    echo "== installing libvirt hook =="
    mkdir -p /etc/libvirt/hooks
    if [ -f "$HOOK" ] && ! grep -q 'win11 VFIO tuning' "$HOOK"; then
        cp -a "$HOOK" "$HOOK.pre-step13.bak"
        echo "   existing hook backed up -> $HOOK.pre-step13.bak"
    fi
    install -m 0755 "$SRC/hooks/qemu" "$HOOK"
    echo "   installed $HOOK"

    echo "== installing ananicy override =="
    mkdir -p "$ANA_DST"
    install -m 0644 "$SRC/ananicy/99-local/qemu-vfio.rules" "$ANA_DST/qemu-vfio.rules"
    echo "   installed $ANA_DST/qemu-vfio.rules"
    if systemctl is-active --quiet ananicy-cpp; then
        systemctl restart ananicy-cpp && echo "   ananicy-cpp restarted"
    else
        echo "   (ananicy-cpp not running -- rule will apply when it starts)"
    fi

    # libvirt caches hook presence at daemon start, so it must be told.
    U=$(libvirt_unit)
    if [ -n "$U" ]; then
        echo "== reloading $U so it picks up the new hook =="
        echo "   (a reload does not disturb running domains)"
        systemctl reload "$U" && echo "   $U reloaded" \
            || echo "   !! reload failed -- run: systemctl restart $U"
    else
        echo "   !! no libvirt daemon active; start one before the next VM start"
    fi

    echo
    echo "== done. Effective on the NEXT VM start. =="
    echo "   For the VM running right now:  sudo $0 apply-now"
    ;;

remove)
    need_root
    echo "== removing libvirt hook =="
    if [ -f "$HOOK" ] && grep -q 'win11 VFIO tuning' "$HOOK"; then
        rm -f "$HOOK"; echo "   removed $HOOK"
        if [ -f "$HOOK.pre-step13.bak" ]; then
            mv "$HOOK.pre-step13.bak" "$HOOK"; echo "   restored previous hook"
        fi
    else
        echo "   not ours / not present, leaving alone"
    fi

    echo "== removing ananicy override =="
    rm -f "$ANA_DST/qemu-vfio.rules" && echo "   removed"
    rmdir "$ANA_DST" 2>/dev/null
    systemctl is-active --quiet ananicy-cpp && systemctl restart ananicy-cpp

    echo "== giving all cores back =="
    set_cpus "$ALL_CPUS"

    U=$(libvirt_unit); [ -n "$U" ] && systemctl reload "$U"
    echo "== removed =="
    ;;

apply-now)
    need_root
    echo "== confining host slices to $HOST_CPUS (VM keeps $VM_CPUS) =="
    set_cpus "$HOST_CPUS"
    echo
    echo "   QEMU is in machine.slice and is NOT affected by the above."
    QP=$(vm_pid || true)
    [ -n "$QP" ] && grep -q machine.slice "/proc/$QP/cgroup" 2>/dev/null \
        && echo "   confirmed: win11 QEMU still in machine.slice"
    ;;

revert-now)
    need_root
    echo "== restoring all cores to the host =="
    set_cpus "$ALL_CPUS"
    ;;

test)
    echo "== hook syntax =="
    bash -n "$SRC/hooks/qemu" && echo "   OK"
    echo
    echo "== hook ignores other guests (must print nothing and exit 0) =="
    bash "$SRC/hooks/qemu" someothervm prepare begin - ; echo "   exit=$?"
    echo
    echo "== hook survives an unknown operation =="
    bash "$SRC/hooks/qemu" win11 migrate begin - ; echo "   exit=$?"
    echo
    echo "== hook exits 0 even unprivileged (a non-zero prepare aborts VM start) =="
    for op in "prepare begin" "started begin" "release end"; do
        bash "$SRC/hooks/qemu" win11 $op - >/dev/null 2>&1
        echo "   $op -> exit=$?"
    done
    echo
    echo "== ananicy rule is valid JSON-per-line =="
    grep -v '^#' "$SRC/ananicy/99-local/qemu-vfio.rules" | grep -v '^$' | while read -r l; do
        echo "$l" | python3 -c 'import json,sys; json.loads(sys.stdin.read()); print("   OK:", end=" ")' \
            && echo "$l"
    done
    ;;

status)
    echo "== libvirt hook =="
    if [ -f "$HOOK" ]; then
        grep -q 'win11 VFIO tuning' "$HOOK" && echo "   installed (ours)" || echo "   present, NOT ours"
    else echo "   not installed"; fi

    echo "== ananicy override =="
    [ -f "$ANA_DST/qemu-vfio.rules" ] && echo "   installed" || echo "   not installed"

    echo "== host slice cpusets =="
    for s in $SLICES; do
        f=/sys/fs/cgroup/$s/cpuset.cpus.effective
        [ -e "$f" ] && echo "   $s: $(cat $f)"
    done

    echo "== stealth intercept knobs =="
    grep . /sys/module/kvm_amd/parameters/stealth_no_*_intercept 2>/dev/null \
        | sed 's|.*/||; s|^|   |' || echo "   patched kvm-amd not loaded"

    PID=$(vm_pid || true)
    if [ -n "$PID" ]; then
        echo "== running win11 QEMU (pid $PID) =="
        echo "   nice   = $(ps -o ni= -p $PID | tr -d ' ')"
        echo "   ionice = $(ionice -p $PID 2>/dev/null)"
        echo "   slice  = $(sed -n 's/^0:://p' /proc/$PID/cgroup | cut -d/ -f2)"
        echo "== vCPU involuntary switches (lower is better) =="
        for t in /proc/$PID/task/*; do
            n=$(cat "$t/comm" 2>/dev/null)
            case "$n" in CPU*KVM*)
                iv=$(grep -m1 nr_involuntary_switches "$t/sched" 2>/dev/null | tr -d ' ' | cut -d: -f2)
                echo "$iv $n";;
            esac
        done | sort -rn | head -4 | sed 's|^|   |'
    else
        echo "== win11 not running =="
    fi

    echo "== hook log (last 6) =="
    tail -6 /var/log/libvirt/hooks-win11.log 2>/dev/null | sed 's|^|   |' || echo "   no log yet"
    ;;

*) echo "usage: $0 [install|remove|status|test|apply-now|revert-now]"; exit 1 ;;
esac
