#!/usr/bin/env python3
"""Add stealth_vmcall_ud: raise #UD instead of #GP for VMCALL at CPL > 0.

VMAware executes VMCALL (0F 01 C1) from user mode. On bare-metal AMD that is an
invalid opcode -> #UD. Under KVM, the #UD is intercepted and emulated, and the
Priv check in x86_emulate_insn() injects #GP instead, which Windows surfaces as
STATUS_ACCESS_VIOLATION -- the signal VMAware reads as "KVM".

The emulator already has the exact flag for this (PrivUD, "#UD instead of #GP on
CPL > 0"); the VMCALL opcode entry simply does not set it. Gating on
ctxt->execute == em_hypercall confines the change to VMCALL: VMMCALL's table
entry carries no Priv flag, so it never reaches this branch.
"""
BASE = "/home/shiroyasha/vfio-acpi/build/cachy/cachyos-7.2.2-1/arch/x86/kvm"

# ---- 1. x86.c: define the knob (non-static; the emulator reads it) ----------
p = BASE + "/x86.c"
s = open(p).read()
if "stealth_vmcall_ud" in s:
    print("x86.c: already applied")
else:
    anchor = ("static bool __read_mostly stealth_no_hypercall_patch = false;\n"
              "module_param(stealth_no_hypercall_patch, bool, 0644);\n")
    assert anchor in s, "x86.c anchor missing"
    add = anchor + """
/*
 * Raise #UD instead of #GP when VMCALL is executed at CPL > 0, matching bare
 * metal where 0F 01 C1 is an invalid opcode on AMD. Consulted directly by the
 * instruction emulator, hence not static. Default off.
 */
bool __read_mostly stealth_vmcall_ud = false;
module_param(stealth_vmcall_ud, bool, 0644);
"""
    s = s.replace(anchor, add, 1)
    open(p, "w").write(s)
    print("x86.c: knob defined")

# ---- 2. emulate.c: extern decl + use it in the Priv check -------------------
p = BASE + "/emulate.c"
s = open(p).read()
if "stealth_vmcall_ud" in s:
    print("emulate.c: already applied")
    raise SystemExit(0)

decl_anchor = "static int em_hypercall(struct x86_emulate_ctxt *ctxt)\n{\n"
assert decl_anchor in s, "emulate.c decl anchor missing"
decl = """/* See stealth_vmcall_ud in x86.c: #UD rather than #GP for VMCALL at CPL > 0. */
extern bool stealth_vmcall_ud;

""" + decl_anchor
s = s.replace(decl_anchor, decl, 1)

old = ("\t\tif ((ctxt->d & Priv) && ops->cpl(ctxt)) {\n"
       "\t\t\tif (ctxt->d & PrivUD)\n"
       "\t\t\t\trc = emulate_ud(ctxt);\n")
new = ("\t\tif ((ctxt->d & Priv) && ops->cpl(ctxt)) {\n"
       "\t\t\tif ((ctxt->d & PrivUD) ||\n"
       "\t\t\t    (stealth_vmcall_ud && ctxt->execute == em_hypercall))\n"
       "\t\t\t\trc = emulate_ud(ctxt);\n")
assert old in s, "emulate.c Priv-check anchor missing"
s = s.replace(old, new, 1)

open(p, "w").write(s)
print("emulate.c: Priv check gated")
