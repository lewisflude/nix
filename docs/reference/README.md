# Reference Documentation

This directory contains technical reference files for the system configuration.

## Files

### `layout.vil`

**MNK88 Keyboard Layout - VIAL Format**

This is the complete keyboard firmware layout for the MNK88 keyboard, used with VIAL software.

**Contents:**
- Layer 0: Base layer with standard QWERTY layout
- Layer 1: RGB/Media control layer
- Layer 2: Navigation layer (Right Option/Alt)
- Layer 3: Function layer (Right Shift hold)

**Key Features:**
- Caps Lock: `LGUI_T(KC_ESC)` - Tap for Escape, Hold for Super/Command
- Right Shift: `LT3(KC_RSHIFT)` - Tap for Shift, Hold for Layer 3
- Right Option: `MO(2)` - Hold for Navigation Layer
- F13: `KC_LGUI` - Super/Command backup

**Usage:**
1. Open VIAL application
2. Connect MNK88 keyboard
3. File → Load Draft Layout
4. Select this file
5. Review changes
6. Save to keyboard

**Documentation:**
- Full key mappings: [keyboard-reference.md](../guides/keyboard-reference.md)
- Setup guide: [keyboard-getting-started.md](../guides/keyboard-getting-started.md)
- macOS specifics: [keyboard-macos.md](../guides/keyboard-macos.md)

**Last Updated:** 2025-10-12  
**Version:** 2.0 Ergonomic Hybrid

---

### `container-stacks.md`

Development container stack documentation.

### `directory-structure.md`

Overview of the nix configuration directory structure.
