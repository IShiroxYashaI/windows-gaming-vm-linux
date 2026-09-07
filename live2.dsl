/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of live2.aml
 *
 * Original Table Header:
 *     Signature        "DSDT"
 *     Length           0x000031C9 (12745)
 *     Revision         0x01 **** 32-bit table (V1), no 64-bit math support
 *     Checksum         0x51
 *     OEM ID           "AMD   "
 *     OEM Table ID     "A M I   "
 *     OEM Revision     0x00000001 (1)
 *     Compiler ID      "AMI "
 *     Compiler Version 0x00000001 (1)
 */
DefinitionBlock ("", "DSDT", 1, "AMD   ", "A M I   ", 0x00000001)
{
    /*
     * iASL Warning: There was 1 external control method found during
     * disassembly, but only 0 were resolved (1 unresolved). Additional
     * ACPI tables may be required to properly disassemble the code. This
     * resulting disassembler output file may not compile because the
     * disassembler did not know how many arguments to assign to the
     * unresolved methods. Note: SSDTs can be dynamically loaded at
     * runtime and may or may not be available via the host OS.
     *
     * To specify the tables needed to resolve external control method
     * references, the -e option can be used to specify the filenames.
     * Example iASL invocations:
     *     iasl -e ssdt1.aml ssdt2.aml ssdt3.aml -d dsdt.aml
     *     iasl -e dsdt.aml ssdt2.aml -d ssdt1.aml
     *     iasl -e ssdt*.aml -d dsdt.aml
     *
     * In addition, the -fe option can be used to specify a file containing
     * control method external declarations with the associated method
     * argument counts. Each line of the file must be of the form:
     *     External (<method pathname>, MethodObj, <argument count>)
     * Invocation:
     *     iasl -fe refs.txt -d dsdt.aml
     *
     * The following methods were unresolved and many not compile properly
     * because the disassembler had to guess at the number of arguments
     * required for each:
     */
    External (_SB_.PCI0.S10_, DeviceObj)
    External (_SB_.PCI0.S11_, DeviceObj)
    External (_SB_.PCI0.S12_, DeviceObj)
    External (_SB_.PCI0.S12_.S00_, DeviceObj)
    External (_SB_.PCI0.S13_, DeviceObj)
    External (_SB_.PCI0.S14_, DeviceObj)
    External (_SB_.PCI0.S15_, DeviceObj)
    External (_SB_.PCI0.S16_, DeviceObj)
    External (_SB_.PCI0.S17_, DeviceObj)
    External (_SB_.PCI0.S18_, DeviceObj)
    External (_SB_.PCI0.S19_, DeviceObj)
    External (_SB_.PCI0.S1A_, DeviceObj)
    External (DVNT, MethodObj)    // Warning: Unknown method, guessing 2 arguments
    External (S00_, DeviceObj)
    External (S10_, DeviceObj)
    External (S11_, DeviceObj)
    External (S12_, DeviceObj)
    External (S13_, DeviceObj)
    External (S14_, DeviceObj)
    External (S15_, DeviceObj)
    External (S16_, DeviceObj)
    External (S17_, DeviceObj)
    External (S18_, DeviceObj)
    External (S19_, DeviceObj)
    External (S1A_, DeviceObj)

    Scope (_SB)
    {
        Name (OSYS, 0x03E8)
        If ((_OSI ("Windows 2001") == One))
        {
            OSYS = 0x07D1
        }

        If ((_OSI ("Windows 2001 SP1") == One))
        {
            OSYS = 0x07D1
        }

        If ((_OSI ("Windows 2001 SP2") == One))
        {
            OSYS = 0x07D2
        }

        If ((_OSI ("Windows 2001.1") == One))
        {
            OSYS = 0x07D3
        }

        If ((_OSI ("Windows 2006") == One))
        {
            OSYS = 0x07D6
        }

        If ((_OSI ("Windows 2009") == One))
        {
            OSYS = 0x07D9
        }

        If ((_OSI ("Windows 2012") == One))
        {
            OSYS = 0x07DC
        }

        If ((_OSI ("Windows 2013") == One))
        {
            OSYS = 0x07DD
        }

        If ((_OSI ("Windows 2015") == One))
        {
            OSYS = 0x07DF
        }

        Device (PCI0)
        {
            Name (_HID, EisaId ("PNP0A08") /* PCI Express Bus */)  // _HID: Hardware ID
            Name (_CID, EisaId ("PNP0A03") /* PCI Bus */)  // _CID: Compatible ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
            {
                CreateDWordField (Arg3, Zero, CDW1)
                If ((Arg0 == ToUUID ("33db4d5b-1ff7-401c-9657-7441c03dd766") /* PCI Host Bridge Device */))
                {
                    CreateDWordField (Arg3, 0x04, CDW2)
                    CreateDWordField (Arg3, 0x08, CDW3)
                    Local0 = CDW3 /* \_SB_.PCI0._OSC.CDW3 */
                    Local0 &= 0x1E
                    If ((Arg1 != One))
                    {
                        CDW1 |= 0x08
                    }

                    If ((CDW3 != Local0))
                    {
                        CDW1 |= 0x10
                    }

                    CDW3 = Local0
                }
                Else
                {
                    CDW1 |= 0x04
                }

                Return (Arg3)
            }

            Method (EDSM, 5, Serialized)
            {
                If ((Arg2 == Zero))
                {
                    Local0 = Buffer (One)
                        {
                             0x00                                             // .
                        }
                    If ((Arg0 != ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))
                    {
                        Return (Local0)
                    }

                    If ((Arg1 < 0x02))
                    {
                        Return (Local0)
                    }

                    Local0 [Zero] = 0x81
                    Return (Local0)
                }

                If ((Arg2 == 0x07))
                {
                    Local0 = Package (0x02)
                        {
                            Zero, 
                            ""
                        }
                    Local1 = DerefOf (Arg4 [Zero])
                    Local0 [Zero] = Local1
                    Return (Local0)
                }
            }
        }

        Device (MCFG)
        {
            Name (_HID, "PNP0C01" /* System Board */)  // _HID: Hardware ID
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0xE0000000,         // Range Minimum
                    0xEFFFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x10000000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
            })
        }

        Device (PCI0.PDRC)
        {
            Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x00B2,             // Range Minimum
                    0x00B2,             // Range Maximum
                    0x01,               // Alignment
                    0x02,               // Length
                    )
            })
            OperationRegion (SMIR, SystemIO, 0xB2, 0x02)
            Field (SMIR, ByteAcc, NoLock, WriteAsZeros)
            {
                SMIC,   8, 
                Offset (0x02)
            }
        }
    }

    Scope (_SB.PCI0)
    {
        OperationRegion (PCST, SystemIO, 0x0CC0, 0x08)
        Field (PCST, DWordAcc, NoLock, WriteAsZeros)
        {
            PCIU,   32, 
            PCID,   32
        }

        OperationRegion (SEJ, SystemIO, 0x0CC8, 0x04)
        Field (SEJ, DWordAcc, NoLock, WriteAsZeros)
        {
            B0EJ,   32
        }

        OperationRegion (BNMR, SystemIO, 0x0CD0, 0x08)
        Field (BNMR, DWordAcc, NoLock, WriteAsZeros)
        {
            BNUM,   32, 
            PIDX,   32
        }

        Mutex (BLCK, 0x00)
        Method (PCEJ, 2, NotSerialized)
        {
            Acquire (BLCK, 0xFFFF)
            BNUM = Arg0
            B0EJ = (One << Arg1)
            Release (BLCK)
            Return (Zero)
        }

        Method (AIDX, 2, NotSerialized)
        {
            Acquire (BLCK, 0xFFFF)
            BNUM = Arg0
            PIDX = (One << Arg1)
            Local0 = PIDX /* \_SB_.PCI0.PIDX */
            Release (BLCK)
            Return (Local0)
        }

        Method (PDSM, 5, Serialized)
        {
            If ((Arg2 == Zero))
            {
                Local0 = Buffer (One)
                    {
                         0x00                                             // .
                    }
                If ((Arg0 != ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))
                {
                    Return (Local0)
                }

                If ((Arg1 < 0x02))
                {
                    Return (Local0)
                }

                Local1 = Zero
                Local2 = AIDX (DerefOf (Arg4 [Zero]), DerefOf (Arg4 [One]
                    ))
                If (!((Local2 == Zero) | (Local2 == 0xFFFFFFFF)))
                {
                    Local1 |= One
                    Local1 |= (One << 0x07)
                }

                Local0 [Zero] = Local1
                Return (Local0)
            }

            If ((Arg2 == 0x07))
            {
                Local2 = AIDX (DerefOf (Arg4 [Zero]), DerefOf (Arg4 [One]
                    ))
                Local0 = Package (0x02){}
                If (!((Local2 == Zero) || (Local2 == 0xFFFFFFFF)))
                {
                    Local0 [Zero] = Local2
                    Local0 [One] = ""
                }

                Return (Local0)
            }
        }
    }

    Name (PICF, Zero)
    Method (_PIC, 1, NotSerialized)  // _PIC: Interrupt Model
    {
        PICF = Arg0
    }

    Scope (_SB)
    {
        Scope (PCI0)
        {
            Name (PRTP, Package (0x80)
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    Zero, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    One, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    0x02, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    0x03, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    Zero, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    One, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    0x02, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    0x03, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    Zero, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    One, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    0x02, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    0x03, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    Zero, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    One, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    0x02, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    0x03, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    Zero, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    One, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    0x02, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    0x03, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    Zero, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    One, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    0x02, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    0x03, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    Zero, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    One, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    0x02, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    0x03, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    Zero, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    One, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    0x02, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    0x03, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    Zero, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    One, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    0x02, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    0x03, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    Zero, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    One, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    0x02, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    0x03, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    Zero, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    One, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    0x02, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    0x03, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    Zero, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    One, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    0x02, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    0x03, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    Zero, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    One, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    0x02, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    0x03, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    Zero, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    One, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    0x02, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    0x03, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    Zero, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    One, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    0x02, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    0x03, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    Zero, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    One, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    0x02, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    0x03, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    Zero, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    One, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    0x02, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    0x03, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    Zero, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    One, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    0x02, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    0x03, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    Zero, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    One, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    0x02, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    0x03, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    Zero, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    One, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    0x02, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    0x03, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    Zero, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    One, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    0x02, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    0x03, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    Zero, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    One, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    0x02, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    0x03, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    Zero, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    One, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    0x02, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    0x03, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    Zero, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    One, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    0x02, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    0x03, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    Zero, 
                    LNKE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    One, 
                    LNKF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    0x02, 
                    LNKG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    0x03, 
                    LNKH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }
            })
            Name (PRTA, Package (0x80)
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    Zero, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    One, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    0x02, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    0x03, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    Zero, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    One, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    0x02, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    0x03, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    Zero, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    One, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    0x02, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    0x03, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    Zero, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    One, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    0x02, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    0x03, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    Zero, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    One, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    0x02, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    0x03, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    Zero, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    One, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    0x02, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    0x03, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    Zero, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    One, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    0x02, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    0x03, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    Zero, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    One, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    0x02, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    0x03, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    Zero, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    One, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    0x02, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    0x03, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    Zero, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    One, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    0x02, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    0x03, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    Zero, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    One, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    0x02, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    0x03, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    Zero, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    One, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    0x02, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    0x03, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    Zero, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    One, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    0x02, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    0x03, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    Zero, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    One, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    0x02, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    0x03, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    Zero, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    One, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    0x02, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    0x03, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    Zero, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    One, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    0x02, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    0x03, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    Zero, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    One, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    0x02, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    0x03, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    Zero, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    One, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    0x02, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    0x03, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    Zero, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    One, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    0x02, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    0x03, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    Zero, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    One, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    0x02, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    0x03, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    Zero, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    One, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    0x02, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    0x03, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    Zero, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    One, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    0x02, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    0x03, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    Zero, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    One, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    0x02, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    0x03, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    Zero, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    One, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    0x02, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    0x03, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    Zero, 
                    GSIA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    One, 
                    GSIB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    0x02, 
                    GSIC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    0x03, 
                    GSID, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    Zero, 
                    GSIA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    One, 
                    GSIB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    0x02, 
                    GSIC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    0x03, 
                    GSID, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    Zero, 
                    GSIA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    One, 
                    GSIB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    0x02, 
                    GSIC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    0x03, 
                    GSID, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    Zero, 
                    GSIA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    One, 
                    GSIB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    0x02, 
                    GSIC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    0x03, 
                    GSID, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    Zero, 
                    GSIA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    One, 
                    GSIB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    0x02, 
                    GSIC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    0x03, 
                    GSID, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    Zero, 
                    GSIE, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    One, 
                    GSIF, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    0x02, 
                    GSIG, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    0x03, 
                    GSIH, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    Zero, 
                    GSIA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    One, 
                    GSIB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    0x02, 
                    GSIC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    0x03, 
                    GSID, 
                    Zero
                }
            })
            Method (_PRT, 0, NotSerialized)  // _PRT: PCI Routing Table
            {
                If ((PICF == Zero))
                {
                    Return (PRTP) /* \_SB_.PCI0.PRTP */
                }
                Else
                {
                    Return (PRTA) /* \_SB_.PCI0.PRTA */
                }
            }
        }

        Method (IQST, 1, NotSerialized)
        {
            If ((0x80 & Arg0))
            {
                Return (0x09)
            }

            Return (0x0B)
        }

        Method (IQCR, 1, Serialized)
        {
            Name (PRR0, ResourceTemplate ()
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, _Y00)
                {
                    0x00000000,
                }
            })
            CreateDWordField (PRR0, \_SB.IQCR._Y00._INT, PRRI)  // _INT: Interrupts
            PRRI = (Arg0 & 0x0F)
            Return (PRR0) /* \_SB_.IQCR.PRR0 */
        }

        Device (LNKA)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQA))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQA |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQA))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQA = PRRI /* \_SB_.LNKA._SRS.PRRI */
            }
        }

        Device (LNKB)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQB))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQB |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQB))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQB = PRRI /* \_SB_.LNKB._SRS.PRRI */
            }
        }

        Device (LNKC)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQC))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQC |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQC))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQC = PRRI /* \_SB_.LNKC._SRS.PRRI */
            }
        }

        Device (LNKD)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQD))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQD |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQD))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQD = PRRI /* \_SB_.LNKD._SRS.PRRI */
            }
        }

        Device (LNKE)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQE))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQE |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQE))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQE = PRRI /* \_SB_.LNKE._SRS.PRRI */
            }
        }

        Device (LNKF)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x05)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQF))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQF |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQF))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQF = PRRI /* \_SB_.LNKF._SRS.PRRI */
            }
        }

        Device (LNKG)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x06)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQG))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQG |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQG))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQG = PRRI /* \_SB_.LNKG._SRS.PRRI */
            }
        }

        Device (LNKH)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000005,
                    0x0000000A,
                    0x0000000B,
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (IQST (PRQH))
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQH |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Return (IQCR (PRQH))
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateDWordField (Arg0, 0x05, PRRI)
                PRQH = PRRI /* \_SB_.LNKH._SRS.PRRI */
            }
        }

        Device (GSIA)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x10)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000010,
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000010,
                }
            })
            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }

        Device (GSIB)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x11)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000011,
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000011,
                }
            })
            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }

        Device (GSIC)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x12)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000012,
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000012,
                }
            })
            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }

        Device (GSID)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x13)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000013,
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000013,
                }
            })
            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }

        Device (GSIE)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x14)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000014,
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000014,
                }
            })
            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }

        Device (GSIF)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x15)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000015,
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000015,
                }
            })
            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }

        Device (GSIG)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x16)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000016,
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000016,
                }
            })
            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }

        Device (GSIH)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x17)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000017,
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, )
                {
                    0x00000017,
                }
            })
            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
            }
        }
    }

    Scope (_GPE)
    {
        Name (_HID, "ACPI0006" /* GPE Block Device */)  // _HID: Hardware ID
    }

    Scope (\_SB.PCI0)
    {
        Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
        {
            WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                0x0000,             // Granularity
                0x0000,             // Range Minimum
                0x00FF,             // Range Maximum
                0x0000,             // Translation Offset
                0x0100,             // Length
                ,, )
            IO (Decode16,
                0x0CF8,             // Range Minimum
                0x0CF8,             // Range Maximum
                0x01,               // Alignment
                0x08,               // Length
                )
            WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                0x0000,             // Granularity
                0x0000,             // Range Minimum
                0x0CF7,             // Range Maximum
                0x0000,             // Translation Offset
                0x0CF8,             // Length
                ,, , TypeStatic, DenseTranslation)
            WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                0x0000,             // Granularity
                0x0D00,             // Range Minimum
                0xFFFF,             // Range Maximum
                0x0000,             // Translation Offset
                0xF300,             // Length
                ,, , TypeStatic, DenseTranslation)
            DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                0x00000000,         // Granularity
                0x000A0000,         // Range Minimum
                0x000BFFFF,         // Range Maximum
                0x00000000,         // Translation Offset
                0x00020000,         // Length
                ,, , AddressRangeMemory, TypeStatic)
            DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                0x00000000,         // Granularity
                0x80000000,         // Range Minimum
                0xDFFFFFFF,         // Range Maximum
                0x00000000,         // Translation Offset
                0x60000000,         // Length
                ,, , AddressRangeMemory, TypeStatic)
            DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                0x00000000,         // Granularity
                0xF0000000,         // Range Minimum
                0xFEBFFFFF,         // Range Maximum
                0x00000000,         // Translation Offset
                0x0EC00000,         // Length
                ,, , AddressRangeMemory, TypeStatic)
            QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                0x0000000000000000, // Granularity
                0x0000380000000000, // Range Minimum
                0x00003857FFFFFFFF, // Range Maximum
                0x0000000000000000, // Translation Offset
                0x0000005800000000, // Length
                ,, , AddressRangeMemory, TypeStatic)
            Memory32Fixed (ReadWrite,
                0xFED40000,         // Address Base
                0x00005000,         // Address Length
                )
        })
        Device (GPER)
        {
            Name (_HID, "PNP0A06" /* Generic Container Device */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x0620,             // Range Minimum
                    0x0620,             // Range Maximum
                    0x01,               // Alignment
                    0x10,               // Length
                    )
            })
        }

        Device (PHPR)
        {
            Name (_HID, "PNP0A06" /* Generic Container Device */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x0CC0,             // Range Minimum
                    0x0CC0,             // Range Maximum
                    0x01,               // Alignment
                    0x18,               // Length
                    )
            })
        }
    }

    Scope (\)
    {
        Name (_S3, Package (0x04)  // _S3_: S3 System State
        {
            One, 
            One, 
            Zero, 
            Zero
        })
        Name (_S4, Package (0x04)  // _S4_: S4 System State
        {
            0x02, 
            0x02, 
            Zero, 
            Zero
        })
        Name (_S5, Package (0x04)  // _S5_: S5 System State
        {
            Zero, 
            Zero, 
            Zero, 
            Zero
        })
    }

    Scope (\_SB)
    {
        Scope (PCI0)
        {
            Device (MCHC)
            {
                Name (_ADR, Zero)  // _ADR: Address
            }

            Device (GFX0)
            {
                Name (_ADR, 0x00020000)  // _ADR: Address
                Device (MCHC)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Name (BSEL, 0x0B)
                Method (DVNT, 2, NotSerialized)
                {
                }
            }

            Device (HDAU)
            {
                Name (_ADR, 0x00020001)  // _ADR: Address
                Device (MCHC)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Name (BSEL, 0x0A)
                Method (DVNT, 2, NotSerialized)
                {
                }
            }

            Device (GFX2)
            {
                Name (_ADR, 0x00020002)  // _ADR: Address
                Device (MCHC)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                    Device (RP08)
                    {
                        Name (_ADR, 0x00010000)  // _ADR: Address
                    }

                    Name (BSEL, 0x09)
                    Device (S00)
                    {
                        Name (_ADR, Zero)  // _ADR: Address
                        Name (ASUN, Zero)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S00_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, Zero)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S10)
                    {
                        Name (_ADR, 0x00020000)  // _ADR: Address
                        Name (ASUN, 0x02)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S10_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x02)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S18)
                    {
                        Name (_ADR, 0x00030000)  // _ADR: Address
                        Name (ASUN, 0x03)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S18_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x03)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S20)
                    {
                        Name (_ADR, 0x00040000)  // _ADR: Address
                        Name (ASUN, 0x04)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S20_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x04)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S28)
                    {
                        Name (_ADR, 0x00050000)  // _ADR: Address
                        Name (ASUN, 0x05)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S28_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x05)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S30)
                    {
                        Name (_ADR, 0x00060000)  // _ADR: Address
                        Name (ASUN, 0x06)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S30_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x06)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S38)
                    {
                        Name (_ADR, 0x00070000)  // _ADR: Address
                        Name (ASUN, 0x07)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S38_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x07)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S40)
                    {
                        Name (_ADR, 0x00080000)  // _ADR: Address
                        Name (ASUN, 0x08)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S40_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x08)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S48)
                    {
                        Name (_ADR, 0x00090000)  // _ADR: Address
                        Name (ASUN, 0x09)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S48_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x09)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S50)
                    {
                        Name (_ADR, 0x000A0000)  // _ADR: Address
                        Name (ASUN, 0x0A)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S50_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x0A)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S58)
                    {
                        Name (_ADR, 0x000B0000)  // _ADR: Address
                        Name (ASUN, 0x0B)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S58_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x0B)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S60)
                    {
                        Name (_ADR, 0x000C0000)  // _ADR: Address
                        Name (ASUN, 0x0C)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S60_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x0C)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S68)
                    {
                        Name (_ADR, 0x000D0000)  // _ADR: Address
                        Name (ASUN, 0x0D)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S68_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x0D)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S70)
                    {
                        Name (_ADR, 0x000E0000)  // _ADR: Address
                        Name (ASUN, 0x0E)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S70_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x0E)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S78)
                    {
                        Name (_ADR, 0x000F0000)  // _ADR: Address
                        Name (ASUN, 0x0F)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S78_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x0F)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S80)
                    {
                        Name (_ADR, 0x00100000)  // _ADR: Address
                        Name (ASUN, 0x10)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S80_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x10)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S88)
                    {
                        Name (_ADR, 0x00110000)  // _ADR: Address
                        Name (ASUN, 0x11)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S88_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x11)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S90)
                    {
                        Name (_ADR, 0x00120000)  // _ADR: Address
                        Name (ASUN, 0x12)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S90_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x12)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (S98)
                    {
                        Name (_ADR, 0x00130000)  // _ADR: Address
                        Name (ASUN, 0x13)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.S98_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x13)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SA0)
                    {
                        Name (_ADR, 0x00140000)  // _ADR: Address
                        Name (ASUN, 0x14)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SA0_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x14)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SA8)
                    {
                        Name (_ADR, 0x00150000)  // _ADR: Address
                        Name (ASUN, 0x15)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SA8_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x15)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SB0)
                    {
                        Name (_ADR, 0x00160000)  // _ADR: Address
                        Name (ASUN, 0x16)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SB0_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x16)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SB8)
                    {
                        Name (_ADR, 0x00170000)  // _ADR: Address
                        Name (ASUN, 0x17)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SB8_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x17)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SC0)
                    {
                        Name (_ADR, 0x00180000)  // _ADR: Address
                        Name (ASUN, 0x18)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SC0_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x18)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SC8)
                    {
                        Name (_ADR, 0x00190000)  // _ADR: Address
                        Name (ASUN, 0x19)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SC8_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x19)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SD0)
                    {
                        Name (_ADR, 0x001A0000)  // _ADR: Address
                        Name (ASUN, 0x1A)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SD0_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x1A)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SD8)
                    {
                        Name (_ADR, 0x001B0000)  // _ADR: Address
                        Name (ASUN, 0x1B)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SD8_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x1B)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SE0)
                    {
                        Name (_ADR, 0x001C0000)  // _ADR: Address
                        Name (ASUN, 0x1C)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SE0_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x1C)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SE8)
                    {
                        Name (_ADR, 0x001D0000)  // _ADR: Address
                        Name (ASUN, 0x1D)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SE8_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x1D)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SF0)
                    {
                        Name (_ADR, 0x001E0000)  // _ADR: Address
                        Name (ASUN, 0x1E)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SF0_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x1E)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Device (SF8)
                    {
                        Name (_ADR, 0x001F0000)  // _ADR: Address
                        Name (ASUN, 0x1F)
                        Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                        {
                            Local0 = Package (0x02)
                                {
                                    Zero, 
                                    Zero
                                }
                            Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX2.MCHC.BSEL */
                            Local0 [One] = ASUN /* \_SB_.PCI0.GFX2.MCHC.SF8_.ASUN */
                            Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                        }

                        Name (_SUN, 0x1F)  // _SUN: Slot User Number
                        Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                        {
                            PCEJ (BSEL, _SUN)
                        }
                    }

                    Method (DVNT, 2, NotSerialized)
                    {
                        If ((Arg0 & One))
                        {
                            Notify (S00, Arg1)
                        }

                        If ((Arg0 & 0x04))
                        {
                            Notify (S10, Arg1)
                        }

                        If ((Arg0 & 0x08))
                        {
                            Notify (S18, Arg1)
                        }

                        If ((Arg0 & 0x10))
                        {
                            Notify (S20, Arg1)
                        }

                        If ((Arg0 & 0x20))
                        {
                            Notify (S28, Arg1)
                        }

                        If ((Arg0 & 0x40))
                        {
                            Notify (S30, Arg1)
                        }

                        If ((Arg0 & 0x80))
                        {
                            Notify (S38, Arg1)
                        }

                        If ((Arg0 & 0x0100))
                        {
                            Notify (S40, Arg1)
                        }

                        If ((Arg0 & 0x0200))
                        {
                            Notify (S48, Arg1)
                        }

                        If ((Arg0 & 0x0400))
                        {
                            Notify (S50, Arg1)
                        }

                        If ((Arg0 & 0x0800))
                        {
                            Notify (S58, Arg1)
                        }

                        If ((Arg0 & 0x1000))
                        {
                            Notify (S60, Arg1)
                        }

                        If ((Arg0 & 0x2000))
                        {
                            Notify (S68, Arg1)
                        }

                        If ((Arg0 & 0x4000))
                        {
                            Notify (S70, Arg1)
                        }

                        If ((Arg0 & 0x8000))
                        {
                            Notify (S78, Arg1)
                        }

                        If ((Arg0 & 0x00010000))
                        {
                            Notify (S80, Arg1)
                        }

                        If ((Arg0 & 0x00020000))
                        {
                            Notify (S88, Arg1)
                        }

                        If ((Arg0 & 0x00040000))
                        {
                            Notify (S90, Arg1)
                        }

                        If ((Arg0 & 0x00080000))
                        {
                            Notify (S98, Arg1)
                        }

                        If ((Arg0 & 0x00100000))
                        {
                            Notify (SA0, Arg1)
                        }

                        If ((Arg0 & 0x00200000))
                        {
                            Notify (SA8, Arg1)
                        }

                        If ((Arg0 & 0x00400000))
                        {
                            Notify (SB0, Arg1)
                        }

                        If ((Arg0 & 0x00800000))
                        {
                            Notify (SB8, Arg1)
                        }

                        If ((Arg0 & 0x01000000))
                        {
                            Notify (SC0, Arg1)
                        }

                        If ((Arg0 & 0x02000000))
                        {
                            Notify (SC8, Arg1)
                        }

                        If ((Arg0 & 0x04000000))
                        {
                            Notify (SD0, Arg1)
                        }

                        If ((Arg0 & 0x08000000))
                        {
                            Notify (SD8, Arg1)
                        }

                        If ((Arg0 & 0x10000000))
                        {
                            Notify (SE0, Arg1)
                        }

                        If ((Arg0 & 0x20000000))
                        {
                            Notify (SE8, Arg1)
                        }

                        If ((Arg0 & 0x40000000))
                        {
                            Notify (SF0, Arg1)
                        }

                        If ((Arg0 & 0x80000000))
                        {
                            Notify (SF8, Arg1)
                        }
                    }
                }

                Name (BSEL, 0x08)
                Method (DVNT, 2, NotSerialized)
                {
                }
            }

            Device (GFX3)
            {
                Name (_ADR, 0x00020003)  // _ADR: Address
                Device (MCHC)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Name (BSEL, 0x07)
                Method (DVNT, 2, NotSerialized)
                {
                }
            }

            Device (GFX4)
            {
                Name (_ADR, 0x00020004)  // _ADR: Address
                Device (MCHC)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Name (BSEL, 0x06)
                Method (DVNT, 2, NotSerialized)
                {
                }
            }

            Device (GFX5)
            {
                Name (_ADR, 0x00020005)  // _ADR: Address
                Device (MCHC)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Name (BSEL, 0x05)
                Method (DVNT, 2, NotSerialized)
                {
                }
            }

            Device (GFX6)
            {
                Name (_ADR, 0x00020006)  // _ADR: Address
                Device (MCHC)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                }

                Name (BSEL, 0x04)
                Method (DVNT, 2, NotSerialized)
                {
                }
            }

            Device (GFX7)
            {
                Name (_ADR, 0x00020007)  // _ADR: Address
                Name (BSEL, 0x03)
                Device (S00)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                    Name (ASUN, Zero)
                    Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                    {
                        Local0 = Package (0x02)
                            {
                                Zero, 
                                Zero
                            }
                        Local0 [Zero] = BSEL /* \_SB_.PCI0.GFX7.BSEL */
                        Local0 [One] = ASUN /* \_SB_.PCI0.GFX7.S00_.ASUN */
                        Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                    }

                    Name (_SUN, Zero)  // _SUN: Slot User Number
                    Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                    {
                        PCEJ (BSEL, _SUN)
                    }
                }

                Method (DVNT, 2, NotSerialized)
                {
                    If ((Arg0 & One))
                    {
                        Notify (S00, Arg1)
                    }
                }
            }

            Device (GLAN)
            {
                Name (_ADR, 0x00030000)  // _ADR: Address
                Name (BSEL, 0x02)
                Device (S00)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                    Name (ASUN, Zero)
                    Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                    {
                        Local0 = Package (0x02)
                            {
                                Zero, 
                                Zero
                            }
                        Local0 [Zero] = BSEL /* \_SB_.PCI0.GLAN.BSEL */
                        Local0 [One] = ASUN /* \_SB_.PCI0.GLAN.S00_.ASUN */
                        Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                    }

                    Name (_SUN, Zero)  // _SUN: Slot User Number
                    Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                    {
                        PCEJ (BSEL, _SUN)
                    }
                }

                Method (DVNT, 2, NotSerialized)
                {
                    If ((Arg0 & One))
                    {
                        Notify (S00, Arg1)
                    }
                }
            }

            Device (NET1)
            {
                Name (_ADR, 0x00030001)  // _ADR: Address
                Name (BSEL, One)
                Device (S00)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                    Name (ASUN, Zero)
                    Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                    {
                        Local0 = Package (0x02)
                            {
                                Zero, 
                                Zero
                            }
                        Local0 [Zero] = BSEL /* \_SB_.PCI0.NET1.BSEL */
                        Local0 [One] = ASUN /* \_SB_.PCI0.NET1.S00_.ASUN */
                        Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                    }

                    Name (_SUN, Zero)  // _SUN: Slot User Number
                    Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                    {
                        PCEJ (BSEL, _SUN)
                    }
                }

                Method (DVNT, 2, NotSerialized)
                {
                    If ((Arg0 & One))
                    {
                        Notify (S00, Arg1)
                    }
                }
            }

            Device (NET2)
            {
                Name (_ADR, 0x00030002)  // _ADR: Address
                Name (BSEL, Zero)
                Device (S00)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                    Name (ASUN, Zero)
                    Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                    {
                        Local0 = Package (0x02)
                            {
                                Zero, 
                                Zero
                            }
                        Local0 [Zero] = BSEL /* \_SB_.PCI0.NET2.BSEL */
                        Local0 [One] = ASUN /* \_SB_.PCI0.NET2.S00_.ASUN */
                        Return (PDSM (Arg0, Arg1, Arg2, Arg3, Local0))
                    }

                    Name (_SUN, Zero)  // _SUN: Slot User Number
                    Method (_EJ0, 1, NotSerialized)  // _EJx: Eject Device, x=0-9
                    {
                        PCEJ (BSEL, _SUN)
                    }
                }

                Method (DVNT, 2, NotSerialized)
                {
                    If ((Arg0 & One))
                    {
                        Notify (S00, Arg1)
                    }
                }
            }

            Device (LPCB)
            {
                Name (_ADR, 0x00140000)  // _ADR: Address
                OperationRegion (PIRQ, PCI_Config, 0x60, 0x0C)
                Scope (\_SB)
                {
                    Field (PCI0.LPCB.PIRQ, ByteAcc, NoLock, Preserve)
                    {
                        PRQA,   8, 
                        PRQB,   8, 
                        PRQC,   8, 
                        PRQD,   8, 
                        Offset (0x08), 
                        PRQE,   8, 
                        PRQF,   8, 
                        PRQG,   8, 
                        PRQH,   8
                    }
                }

                Device (TPM)
                {
                    Name (_HID, "MSFT0101" /* TPM 2.0 Security Device */)  // _HID: Hardware ID
                    Name (_STR, "TPM 2.0 Device")  // _STR: Description String
                    Name (_UID, One)  // _UID: Unique ID
                    Name (_STA, 0x0F)  // _STA: Status
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        Memory32Fixed (ReadWrite,
                            0xFED40000,         // Address Base
                            0x00005000,         // Address Length
                            )
                    })
                    OperationRegion (TPP2, SystemMemory, 0xFED45100, 0x5A)
                    Field (TPP2, AnyAcc, NoLock, Preserve)
                    {
                        PPIN,   8, 
                        PPIP,   32, 
                        PPRP,   32, 
                        PPRQ,   32, 
                        PPRM,   32, 
                        LPPR,   32
                    }

                    OperationRegion (TPP3, SystemMemory, 0xFED4515A, One)
                    Field (TPP3, ByteAcc, NoLock, Preserve)
                    {
                        MOVV,   8
                    }

                    Method (TPFN, 1, Serialized)
                    {
                        If ((Arg0 >= 0x0100))
                        {
                            Return (Zero)
                        }

                        OperationRegion (TPP1, SystemMemory, (0xFED45000 + Arg0), One)
                        Field (TPP1, ByteAcc, NoLock, Preserve)
                        {
                            TPPF,   8
                        }

                        Return (TPPF) /* \_SB_.PCI0.LPCB.TPM_.TPFN.TPPF */
                    }

                    Name (TPM2, Package (0x02)
                    {
                        Zero, 
                        Zero
                    })
                    Name (TPM3, Package (0x03)
                    {
                        Zero, 
                        Zero, 
                        Zero
                    })
                    Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                    {
                        If ((Arg0 == ToUUID ("3dddfaa6-361b-4eb4-a424-8d10089d1653") /* Physical Presence Interface */))
                        {
                            If ((Arg2 == Zero))
                            {
                                Return (Buffer (0x02)
                                {
                                     0xFF, 0x01                                       // ..
                                })
                            }

                            If ((Arg2 == One))
                            {
                                Return ("1.3")
                            }

                            If ((Arg2 == 0x02))
                            {
                                Local0 = DerefOf (Arg3 [Zero])
                                Local1 = TPFN (Local0)
                                If (((Local1 & 0x07) == Zero))
                                {
                                    Return (One)
                                }

                                PPRQ = Local0
                                PPRM = Zero
                                Return (Zero)
                            }

                            If ((Arg2 == 0x03))
                            {
                                If ((Arg1 == One))
                                {
                                    TPM2 [One] = PPRQ /* \_SB_.PCI0.LPCB.TPM_.PPRQ */
                                    Return (TPM2) /* \_SB_.PCI0.LPCB.TPM_.TPM2 */
                                }

                                If ((Arg1 == 0x02))
                                {
                                    TPM3 [One] = PPRQ /* \_SB_.PCI0.LPCB.TPM_.PPRQ */
                                    TPM3 [0x02] = PPRM /* \_SB_.PCI0.LPCB.TPM_.PPRM */
                                    Return (TPM3) /* \_SB_.PCI0.LPCB.TPM_.TPM3 */
                                }
                            }

                            If ((Arg2 == 0x04))
                            {
                                Return (0x02)
                            }

                            If ((Arg2 == 0x05))
                            {
                                TPM3 [One] = LPPR /* \_SB_.PCI0.LPCB.TPM_.LPPR */
                                TPM3 [0x02] = PPRP /* \_SB_.PCI0.LPCB.TPM_.PPRP */
                                Return (TPM3) /* \_SB_.PCI0.LPCB.TPM_.TPM3 */
                            }

                            If ((Arg2 == 0x06))
                            {
                                Return (0x03)
                            }

                            If ((Arg2 == 0x07))
                            {
                                Local0 = DerefOf (Arg3 [Zero])
                                Local1 = TPFN (Local0)
                                If (((Local1 & 0x07) == Zero))
                                {
                                    Return (One)
                                }

                                If (((Local1 & 0x07) == 0x02))
                                {
                                    Return (0x03)
                                }

                                If ((Arg1 == One))
                                {
                                    PPRQ = Local0
                                    PPRM = Zero
                                }

                                If ((Arg1 == 0x02))
                                {
                                    PPRQ = Local0
                                    PPRM = DerefOf (Arg3 [One])
                                }

                                Return (Zero)
                            }

                            If ((Arg2 == 0x08))
                            {
                                Local0 = DerefOf (Arg3 [Zero])
                                Local1 = TPFN (Local0)
                                Return ((Local1 & 0x07))
                            }

                            Return (Buffer (One)
                            {
                                 0x00                                             // .
                            })
                        }

                        If ((Arg0 == ToUUID ("376054ed-cc13-4675-901c-4756d7f2d45d") /* TPM Memory Clear */))
                        {
                            If ((Arg2 == Zero))
                            {
                                Return (Buffer (One)
                                {
                                     0x03                                             // .
                                })
                            }

                            If ((Arg2 == One))
                            {
                                Local0 = DerefOf (Arg3 [Zero])
                                MOVV = Local0
                                Return (Zero)
                            }
                        }
                    }
                }

                Device (KBD)
                {
                    Name (_HID, EisaId ("PNP0303") /* IBM Enhanced Keyboard (101/102-key, PS/2 Mouse) */)  // _HID: Hardware ID
                    Name (_STA, 0x0F)  // _STA: Status
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0060,             // Range Minimum
                            0x0060,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0064,             // Range Minimum
                            0x0064,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IRQNoFlags ()
                            {1}
                    })
                }

                Device (MOU)
                {
                    Name (_HID, EisaId ("PNP0F13") /* PS/2 Mouse */)  // _HID: Hardware ID
                    Name (_STA, 0x0F)  // _STA: Status
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IRQNoFlags ()
                            {12}
                    })
                }

                Device (RTC)
                {
                    Name (_HID, EisaId ("PNP0B00") /* AT Real-Time Clock */)  // _HID: Hardware ID
                    Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                    {
                        IO (Decode16,
                            0x0070,             // Range Minimum
                            0x0070,             // Range Maximum
                            0x01,               // Alignment
                            0x08,               // Length
                            )
                        IRQNoFlags ()
                            {8}
                    })
                }
            }

            Device (SAT1)
            {
                Name (_ADR, 0x00140002)  // _ADR: Address
            }

            Device (SBUS)
            {
                Name (_ADR, 0x00140003)  // _ADR: Address
            }

            Device (RPD8)
            {
                Name (_ADR, 0x001B0000)  // _ADR: Address
            }
        }
    }

    Scope (\_SB.PCI0)
    {
        Scope (S1A)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = Zero
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S19)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = One
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S18)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x02
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S17)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x03
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S16)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x04
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S15)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x05
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S14)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x06
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S13)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x07
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S12)
        {
            Scope (S00)
            {
                Method (PCNT, 0, NotSerialized)
                {
                    BNUM = 0x09
                    DVNT (PCIU, One)
                    DVNT (PCID, 0x03)
                }
            }

            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x08
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
                ^S00.PCNT ()
            }
        }

        Scope (S11)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x0A
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Scope (S10)
        {
            Method (PCNT, 0, NotSerialized)
            {
                BNUM = 0x0B
                DVNT (PCIU, One)
                DVNT (PCID, 0x03)
            }
        }

        Method (PCNT, 0, NotSerialized)
        {
            ^S1A.PCNT ()
            ^S19.PCNT ()
            ^S18.PCNT ()
            ^S17.PCNT ()
            ^S16.PCNT ()
            ^S15.PCNT ()
            ^S14.PCNT ()
            ^S13.PCNT ()
            ^S12.PCNT ()
            ^S11.PCNT ()
            ^S10.PCNT ()
        }
    }

    Scope (_GPE)
    {
        Method (_E01, 0, NotSerialized)  // _Exx: Edge-Triggered GPE, xx=0x00-0xFF
        {
            Acquire (\_SB.PCI0.BLCK, 0xFFFF)
            \_SB.PCI0.PCNT ()
            Release (\_SB.PCI0.BLCK)
        }
    }
}

