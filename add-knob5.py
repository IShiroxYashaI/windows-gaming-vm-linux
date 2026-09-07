#!/usr/bin/env python3
"""Add stealth_no_cpuid_intercept: let the guest execute CPUID natively.

VMAware's TIMER check times CPUID against a cross-core software counter and
flags a hypervisor when the ratio exceeds 2.5. On VMX, CPUID is an
unconditional VM exit and this is unwinnable. SVM makes the interception
optional (INTERCEPT_CPUID is a plain VMCB intercept bit), so clearing it drops
the exit entirely and the instruction runs at native cost.

Synced from svm_vcpu_run() rather than init_vmcb() so the knob can be flipped
at runtime: the guest OS still enumerates CPU topology through the emulated
path while booting, and only later CPUID executions run raw.
"""
BASE = "/home/shiroyasha/vfio-acpi/build/cachy/cachyos-7.2.2-1/arch/x86/kvm/svm"

p = BASE + "/svm.c"
s = open(p).read()
if "stealth_no_cpuid_intercept" in s:
    print("svm.c: already applied")
    raise SystemExit(0)

# ---- 1. define the knob next to the existing stealth param -----------------
anchor = ("static bool __ro_after_init stealth_svm_ud = false;\n"
          "module_param(stealth_svm_ud, bool, 0444);\n")
assert anchor in s, "svm.c param anchor missing"
add = anchor + """
/*
 * Stop intercepting CPUID so the guest executes it natively. Writable at
 * runtime on purpose: leave it off across guest boot so the OS enumerates
 * topology through the emulated path, then flip it on afterwards.
 */
static bool __read_mostly stealth_no_cpuid_intercept = false;
module_param(stealth_no_cpuid_intercept, bool, 0644);
"""
s = s.replace(anchor, add, 1)

# ---- 2. sync the VMCB intercept bit on each entry --------------------------
old = ("\tunsigned enter_flags = 0;\n"
       "\n"
       "\tif (!msr_write_intercepted(svm, MSR_IA32_SPEC_CTRL))\n")
assert old in s, "svm_vcpu_run anchor missing"
new = ("\tunsigned enter_flags = 0;\n"
       "\n"
       "\t/*\n"
       "\t * Unlike VMX, SVM makes CPUID interception optional, so the guest can\n"
       "\t * run it without a #VMEXIT. Skipped while in guest mode because\n"
       "\t * svm_set/clr_intercept() write vmcb01 while svm_is_intercept() reads\n"
       "\t * the active vmcb02, and the two would disagree.\n"
       "\t */\n"
       "\tif (unlikely(!is_guest_mode(vcpu) &&\n"
       "\t\t     stealth_no_cpuid_intercept ==\n"
       "\t\t     svm_is_intercept(svm, INTERCEPT_CPUID))) {\n"
       "\t\tif (stealth_no_cpuid_intercept)\n"
       "\t\t\tsvm_clr_intercept(svm, INTERCEPT_CPUID);\n"
       "\t\telse\n"
       "\t\t\tsvm_set_intercept(svm, INTERCEPT_CPUID);\n"
       "\t}\n"
       "\n"
       "\tif (!msr_write_intercepted(svm, MSR_IA32_SPEC_CTRL))\n")
s = s.replace(old, new, 1)

open(p, "w").write(s)
print("svm.c: knob defined + vcpu_run sync added")
