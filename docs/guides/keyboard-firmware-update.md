# Firmware Update Guide for v2.0 Ergonomic Hybrid Layout

**Last Updated:** 2025-10-12

This guide provides the simple, mandatory firmware instruction required for the v2.0 Ergonomic Hybrid keyboard layout to function correctly.

---

## The Golden Rule: Keep Firmware Simple

The entire philosophy of the v2.0 setup is to move logical complexity from the keyboard firmware to the operating system (via `keyd`). Your keyboard's only job is to send simple, standard keycodes.

### The Single Most Important Change

To allow `keyd` to handle the "Hold for Super, Tap for Escape" functionality, your keyboard's Caps Lock key **must be configured to send a standard `KC_CAPS` keycode.**

**Incorrect Configuration (Legacy):**
- `LT(1, KC_CAPS)`
- `MT(MOD_LCTL, KC_CAPS)`
- Any other complex, dual-function key.

**Correct Configuration (v2.0+):**
- `KC_CAPS`

---

## How to Update Your Firmware

1.  **Open Your Firmware Editor:**
    - Launch VIA, VIAL, or whatever software you use to configure your keyboard.

2.  **Select the Caps Lock Key:**
    - On the base layer (Layer 0), click on the key at the Caps Lock position (typically index 51 on a TKL).

3.  **Assign the Correct Keycode:**
    - Go to the "Basic" or "Keys" section.
    - Select `KC_CAPS` (it may be shown as just `Caps`).
    - Ensure there are no "Layer Tap," "Momentary," or other special functions assigned to it on the base layer.

4.  **Save and Flash:**
    - Save your layout.
    - If necessary, flash the updated firmware to your keyboard.

---

## Verification

After updating, you can verify the change with a key event viewer like `wev`.

- When you press and release Caps Lock, you should see `KEY_CAPSLOCK` events.
- If you see layer change events or other modifier events, the firmware is not configured correctly.

Once `keyd` is running with the v2.0 configuration, it will intercept this `KEY_CAPSLOCK` event and correctly translate it into either `KEY_ESC` (on tap) or `KEY_LEFTMETA` (on hold).