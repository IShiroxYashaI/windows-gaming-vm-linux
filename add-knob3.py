#!/usr/bin/env python3
"""Add the stealth_no_hypercall_patch knob to arch/x86/kvm/x86.c."""
p = "/home/shiroyasha/vfio-acpi/build/cachy/cachyos-7.2.2-1/arch/x86/kvm/x86.c"
s = open(p).read()

if "stealth_no_hypercall_patch" in s:
    print("already applied")
    raise SystemExit(0)

# 1) declare the knob next to the existing hypercall knob
anchor = ("static bool __read_mostly stealth_hypercall_ud = false;\n"
          "module_param(stealth_hypercall_ud, bool, 0644);\n")
assert anchor in s, "anchor 1 missing"

add = anchor + """
/*
 * Force the KVM_X86_QUIRK_FIX_HYPERCALL_INSN-disabled behaviour unconditionally:
 * never rewrite a mismatched hypercall instruction in guest memory, synthesize
 * #UD instead. The rewrite targets the guest's own code page via
 * emulator_write_emulated(); when that page is read-only the write faults and
 * the guest observes a #PF where bare metal raises #UD. This takes the same
 * path the quirk-disabled case already uses upstream. Default off.
 */
static bool __read_mostly stealth_no_hypercall_patch = false;
module_param(stealth_no_hypercall_patch, bool, 0644);
"""
s = s.replace(anchor, add, 1)

# 2) force the #UD path in emulator_fix_hypercall
old = ("\tif (!kvm_check_has_quirk(vcpu->kvm, KVM_X86_QUIRK_FIX_HYPERCALL_INSN)) {\n"
       "\t\tctxt->exception.error_code_valid = false;")
new = ("\tif (stealth_no_hypercall_patch ||\n"
       "\t    !kvm_check_has_quirk(vcpu->kvm, KVM_X86_QUIRK_FIX_HYPERCALL_INSN)) {\n"
       "\t\tctxt->exception.error_code_valid = false;")
assert old in s, "anchor 2 missing"
s = s.replace(old, new, 1)

open(p, "w").write(s)
print("edits applied")
