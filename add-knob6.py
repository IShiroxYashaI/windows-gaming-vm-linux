#!/usr/bin/env python3
"""Add stealth_no_rdpru_intercept: let the guest execute RDPRU natively.

Companion to stealth_no_cpuid_intercept. Once CPUID is no longer intercepted
the guest reads the raw host Fn8000_0008_EBX[4] and believes RDPRU exists, but
KVM still intercepts it and routes SVM_EXIT_RDPRU to kvm_handle_invalid_op(),
injecting #UD. Software that feature-detects then faults -- VMAware's
INTERRUPT_SHADOW check dies there with EXCEPTION_ILLEGAL_INSTRUCTION.

Injecting a different exception does not help: that check resumes only on
EXCEPTION_SINGLE_STEP, which requires RDPRU to retire without faulting so the
#DB deferred by the preceding MOV SS interrupt shadow lands on the next
instruction. Clearing the intercept reproduces hardware exactly. RDPRU is
CPL3-executable on AMD; the cost is that the guest reads the host core's
MPERF/APERF.
"""
BASE = "/home/shiroyasha/vfio-acpi/build/cachy/cachyos-7.2.2-1/arch/x86/kvm/svm"

p = BASE + "/svm.c"
s = open(p).read()
if "stealth_no_rdpru_intercept" in s:
    print("svm.c: already applied")
    raise SystemExit(0)

anchor = ("static bool __read_mostly stealth_no_cpuid_intercept = false;\n"
          "module_param(stealth_no_cpuid_intercept, bool, 0644);\n")
assert anchor in s, "svm.c cpuid-knob anchor missing"
add = anchor + """
/*
 * Stop intercepting RDPRU so it retires natively instead of taking KVM's #UD.
 * Only meaningful alongside stealth_no_cpuid_intercept, which is what lets the
 * guest see the feature bit in the first place.
 */
static bool __read_mostly stealth_no_rdpru_intercept = false;
module_param(stealth_no_rdpru_intercept, bool, 0644);
"""
s = s.replace(anchor, add, 1)

old = ("\t\tif (stealth_no_cpuid_intercept)\n"
       "\t\t\tsvm_clr_intercept(svm, INTERCEPT_CPUID);\n"
       "\t\telse\n"
       "\t\t\tsvm_set_intercept(svm, INTERCEPT_CPUID);\n"
       "\t}\n")
assert old in s, "svm_vcpu_run cpuid sync anchor missing"
new = old + """
	if (unlikely(!is_guest_mode(vcpu) &&
		     stealth_no_rdpru_intercept ==
		     svm_is_intercept(svm, INTERCEPT_RDPRU))) {
		if (stealth_no_rdpru_intercept)
			svm_clr_intercept(svm, INTERCEPT_RDPRU);
		else
			svm_set_intercept(svm, INTERCEPT_RDPRU);
	}
"""
s = s.replace(old, new, 1)

open(p, "w").write(s)
print("svm.c: rdpru knob defined + vcpu_run sync added")
