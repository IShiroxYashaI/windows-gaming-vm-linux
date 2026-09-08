#!/usr/bin/env bash
# One-command health check for the whole stack. Needs no root.
#   ./check.sh
# Exits non-zero if anything is broken. Every failure prints the command to fix it.
set -uo pipefail
cd "$(dirname "$0")"
source ./kver.sh 2>/dev/null || { echo "!! cannot source kver.sh"; exit 1; }

FIXES=()
RC=0

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

ok()   { printf '  [ \033[32mOK\033[0m ] %-22s %s\n' "$1" "$2"; }
warn() { printf '  [\033[33mWARN\033[0m] %-22s %s\n' "$1" "$2"; [ $# -gt 2 ] && FIXES+=("$3"); }
bad()  { printf '  [\033[31mFAIL\033[0m] %-22s %s\n' "$1" "$2"; [ $# -gt 2 ] && FIXES+=("$3"); RC=1; }

PID=$(vm_pid || true)

echo "== kernel and modules =="
ok "running kernel" "$KREL"

if [ -f kmod/patched/kvm-amd.ko ]; then
    BV=$(modinfo -F vermagic kmod/patched/kvm-amd.ko 2>/dev/null | awk '{print $1}')
    if [ "$BV" = "$KREL" ]; then ok "built modules" "vermagic $BV"
    else bad "built modules" "built for $BV, running $KREL" \
             "./kern-prep.sh && ./apply-patch.sh && ./kern-build-kvm.sh patched"; fi
else
    warn "built modules" "kmod/patched/ absent (not tracked in git)" \
         "./kern-prep.sh && ./apply-patch.sh && ./kern-build-kvm.sh patched"
fi

LOADED=$(cat /sys/module/kvm_amd/srcversion 2>/dev/null || echo none)
BUILT=$(modinfo -F srcversion kmod/patched/kvm-amd.ko 2>/dev/null || echo nobuild)
DISTRO=$(modinfo -F srcversion kvm_amd 2>/dev/null || echo nodistro)
if   [ "$LOADED" = none ];    then bad  "loaded modules" "kvm_amd not loaded" "sudo ./root-step10-kvm-swap.sh patched"
elif [ "$LOADED" = "$BUILT" ];then ok   "loaded modules" "our patched build"
elif [ "$LOADED" = "$DISTRO" ];then warn "loaded modules" "distro kvm_amd -- no stealth (8/85)" \
                                        "sudo ./root-step10-kvm-swap.sh patched"
else warn "loaded modules" "unrecognised srcversion $LOADED"; fi

T=$(cat /proc/sys/kernel/tainted 2>/dev/null || echo 0)
if [ $(( T & 2 )) -ne 0 ]; then
    bad "kernel taint" "$T -- FORCED module loaded, source did not match" \
        "rebuild; never use insmod -f"
else
    ok "kernel taint" "$T (no forced-module bit)"
fi

echo "== stealth knobs =="
SAFE_ON=0; SAFE_TOTAL=0
for k in /sys/module/kvm/parameters/stealth_hypercall_ud \
         /sys/module/kvm/parameters/stealth_no_hypercall_patch \
         /sys/module/kvm/parameters/stealth_vmcall_ud \
         /sys/module/kvm_amd/parameters/stealth_svm_ud; do
    [ -e "$k" ] || continue
    SAFE_TOTAL=$((SAFE_TOTAL+1)); [ "$(cat "$k")" = Y ] && SAFE_ON=$((SAFE_ON+1))
done
if [ "$SAFE_TOTAL" = 0 ]; then bad "safe knobs" "absent -- patched build not loaded" "sudo ./root-step10-kvm-swap.sh patched"
elif [ "$SAFE_ON" = 4 ];  then ok  "safe knobs" "4/4 on  -> 1/85"
else warn "safe knobs" "$SAFE_ON/$SAFE_TOTAL on" "sudo ./root-step10-kvm-swap.sh patched"; fi

C=$(cat /sys/module/kvm_amd/parameters/stealth_no_cpuid_intercept 2>/dev/null || echo -)
R=$(cat /sys/module/kvm_amd/parameters/stealth_no_rdpru_intercept 2>/dev/null || echo -)
case "$C$R" in
  YY) ok   "max knobs" "both on -> 0/85  (run max-off before restarting Windows)" ;;
  NN) warn "max knobs" "both off -> 1/85" "sudo ./root-step10-kvm-swap.sh max-on   # after Windows is up" ;;
  --) : ;;
  *)  bad  "max knobs" "MISMATCHED cpuid=$C rdpru=$R -- guest may take a #UD" \
           "sudo ./root-step10-kvm-swap.sh max-off" ;;
esac

echo "== persistence =="
E=$(systemctl is-enabled kvm-stealth.service 2>/dev/null || echo missing)
A=$(systemctl is-active  kvm-stealth.service 2>/dev/null || echo inactive)
if [ "$E" = enabled ]; then ok "kvm-stealth.service" "$E, $A"
else warn "kvm-stealth.service" "$E -- patched KVM will not load at boot" \
          "sudo ./root-step12-persist.sh install"; fi

echo "== host tuning =="
H=/etc/libvirt/hooks/qemu
HOOK_OK=0
if [ ! -f "$H" ]; then warn "libvirt hook" "not installed" "sudo ./root-step13-vm-tuning.sh install"
elif grep -q 'win11 VFIO tuning' "$H" 2>/dev/null; then ok "libvirt hook" "installed"; HOOK_OK=1
else warn "libvirt hook" "present but not ours" "sudo ./root-step13-vm-tuning.sh install"; fi

if [ -f /etc/ananicy.d/99-local/qemu-vfio.rules ]; then ok "ananicy override" "installed"
else warn "ananicy override" "absent -- QEMU runs at nice 9, ionice 7" \
          "sudo ./root-step13-vm-tuning.sh install"; fi

ISO=$(cat /sys/fs/cgroup/system.slice/cpuset.cpus.effective 2>/dev/null || echo '?')
if [ "$ISO" = "0-17,24-41" ]; then ok "core isolation" "host slices on $ISO"
elif [ -n "$PID" ]; then
    warn "core isolation" "system.slice on $ISO -- host shares the vCPU cores" \
         "sudo ./root-step13-vm-tuning.sh apply-now"
elif [ "$HOOK_OK" = 1 ]; then
    ok "core isolation" "host on $ISO; the hook applies it when the VM starts"
else
    warn "core isolation" "system.slice on $ISO -- nothing will apply it" \
         "sudo ./root-step13-vm-tuning.sh install"
fi

echo "== vm =="
if [ -z "$PID" ]; then
    ok "win11" "not running"
else
    ok "win11" "running (pid $PID)"
    N=$(ps -o ni= -p "$PID" | tr -d ' ')
    IO=$(ionice -p "$PID" 2>/dev/null)
    if [ "$N" = 0 ]; then ok "qemu priority" "nice $N, $IO"
    else warn "qemu priority" "nice $N, $IO" "sudo ./root-step13-vm-tuning.sh install"; fi
    WORST=$(for t in /proc/$PID/task/*; do
              case "$(cat "$t/comm" 2>/dev/null)" in CPU*KVM*)
                grep -m1 nr_involuntary_switches "$t/sched" 2>/dev/null | tr -d ' ' | cut -d: -f2;;
              esac; done | sort -rn | head -1)
    UP=$(ps -o etimes= -p "$PID" | tr -d ' ')
    if [ -n "$WORST" ] && [ "$UP" -gt 60 ]; then
        RATE=$(( WORST / UP ))
        if [ "$RATE" -lt 10 ]; then ok "vcpu preemption" "worst ${RATE}/s"
        else warn "vcpu preemption" "worst ${RATE}/s across ${UP}s" \
                  "sudo ./root-step13-vm-tuning.sh apply-now"; fi
    fi
fi

echo
if [ ${#FIXES[@]} -eq 0 ]; then
    echo "== everything looks right =="
else
    echo "== to fix =="
    # absolute paths: check.sh runs from anywhere, and a bare ./ fails if the
    # shell is not sitting in this directory
    printf '   %s\n' "${FIXES[@]}" | awk '!seen[$0]++' | sed "s|\./|$KBUILD_ROOT/|g"
fi
exit $RC
