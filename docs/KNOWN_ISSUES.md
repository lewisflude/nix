# Known Issues

This document tracks known issues in the system configuration and their status.

## ACPI BIOS Bug (NVIDIA GPU) - Unfixable

**Status:** ⚠️ Harmless, cannot be fixed in software

**Error Message:**

```
ACPI BIOS Error (bug): Failure creating named object [\_SB.PC00.PEG1.PEGP._DSM.USRG], AE_ALREADY_EXISTS
ACPI Error: Aborting method \_SB.PC00.PEG1.PEGP._DSM due to previous error (AE_ALREADY_EXISTS)
```

**Details:**

- **Motherboard:** ASUS ProArt Z790-CREATOR WIFI
- **BIOS Version:** 2801 (11/29/2024)
- **Affected Component:** NVIDIA GPU ACPI methods
- **Impact:** None - purely cosmetic error in kernel logs

**Root Cause:**
This is a bug in the ASUS BIOS firmware where the ACPI code for the NVIDIA GPU tries to create an object (`USRG`) that already exists. This happens during PCIe GPU initialization.

**Why It Can't Be Fixed:**

1. This is a **BIOS firmware bug**, not a Linux/NixOS issue
2. Requires ASUS to release a BIOS update with fixed ACPI tables
3. The error occurs before the OS has full control of the hardware

**Workaround:**
None needed - the error is harmless and doesn't affect:

- GPU functionality
- Gaming performance
- System stability
- Power management

**Should I Update BIOS?**
Check [ASUS Support Page](https://www.asus.com/supportonly/proart%20z790-creator%20wifi/helpdesk_bios/) for newer BIOS versions that might fix this issue. However:

- ⚠️ BIOS updates carry risk of bricking the motherboard
- ✅ Current BIOS (2801 from Nov 2024) is recent
- 💡 Only update if ASUS release notes specifically mention ACPI fixes

**Recommendation:** Leave as-is unless experiencing actual GPU issues.

---

## Fixed Issues

### ✅ Fuzzel Invalid Keybinding

**Fixed in:** `a51a201` (Dec 18, 2025)

Removed invalid `delete-to-end-of-line` keybinding from fuzzel configuration. This action doesn't exist in fuzzel and was causing warning messages.

### ✅ Apogee USB Audio Quirk Messages

**Fixed in:** `a51a201` (Dec 18, 2025)

Added kernel parameter `usbcore.quirks=0c60:002a:b` to suppress harmless error messages when the Apogee Symphony Desktop tries to query 192kHz sample rate support. We use 48kHz, so these errors don't affect functionality.

### ✅ Audio Crackling in Games

**Fixed in:** Multiple commits (Dec 18, 2025)

- `16564b6` - Gaming latency buffer configuration
- `6789e08` - WirePlumber routing corrections
- `1c6ad3d` - Dynamic latency calculation

Resolved buffer underruns and incorrect audio routing that caused crackling during gameplay.
