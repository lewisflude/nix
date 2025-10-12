# Migration Guide: F13-Only to v2.0 Ergonomic Hybrid

**Last Updated:** 2025-10-12

This guide provides a clear path for transitioning from the legacy F13-only setup to the new v2.0 ergonomic hybrid configuration. The new setup is significantly faster and more ergonomic, and this guide is designed to make the transition seamless.

---

## What's Changing

### Old Setup (Legacy)
- **Primary Modifier:** `F13` (on the function row).
- **Navigation:** Handled by a firmware layer, often on `Caps Lock (Hold)`.
- **Escape:** Physical `Esc` key.

### New Setup (v2.0 Ergonomic Hybrid)
- **Primary Modifier:** `Caps Lock (Hold)` → `Super` (on the home row).
- **Backup Modifier:** `F13` → `Super` (still works for complex chords).
- **Navigation:** `Right Alt (Hold)` → OS-level `nav` layer (Vim bindings everywhere).
- **Escape:** `Caps Lock (Tap)` → `Esc` (a convenient bonus).

---

## The Action Plan: A Phased Migration

Follow this timeline to retrain your muscle memory with minimal disruption.

### Phase 1: Configuration Update (10 Minutes)

**1. Apply the NixOS Configuration:**
   The `keyd.nix` file has already been updated with the new v2.0 configuration. Simply apply it:
   ```bash
   cd ~/.config/nix
   sudo nixos-rebuild switch --flake .
   ```

**2. Update Keyboard Firmware:**
   For the new system to work, your keyboard **must** send a standard `KC_CAPS` keycode for the Caps Lock key. The old firmware layer must be disabled.
   - See the **[Firmware Update Guide](keyboard-firmware-update.md)** for instructions.

**3. Test the New Setup:**
   Use a key event viewer like `wev` to confirm everything is working as expected:
   - **Caps Tap:** Press and release `Caps Lock` quickly. Output should be `KEY_ESC`.
   - **Caps Hold:** Hold `Caps Lock` and press `T`. A terminal should open. `wev` should show `KEY_LEFTMETA` for the hold.
   - **Right Alt Nav:** Hold `Right Alt` and press `H`. The cursor should move left. `wev` should show `KEY_LEFT`.
   - **F13 Backup:** Hold `F13` and press `T`. A terminal should still open.

---

### Phase 2: Learning the Ropes (Week 1)

**Goal:** Build initial comfort with the new home-row-centric workflow. **F13 is still your safety net.**

- **Days 1-2: Basic Window Management**
  - Practice using `Caps + T/D/Q/1-9` for your most common window management tasks.
  - If you forget, just use `F13`. Don't stress. The goal is practice, not perfection.

- **Days 3-7: Master the Navigation Layer**
  - Start using `Right Alt + H/J/K/L` for all text navigation.
  - Practice `Right Alt + Y/O` for Home/End and `I/U` for Page Up/Down in your editor and browser.
  - **Challenge:** Try to go a full hour without touching your physical arrow keys.

---

### Phase 3: Building Muscle Memory (Week 2)

**Goal:** Make `Caps Lock` your default modifier. Phase out `F13` for all single-modifier shortcuts.

- **Force the Change:** Consciously choose `Caps Lock` for every `Mod+...` shortcut.
- **Expand Your Vocabulary:** Integrate more `Right Alt` layer shortcuts like word-wise navigation (`W/B`) and editing commands (`C/V/X/Z`).
- **Embrace `Caps Tap`:** If you use Vim or Helix, start using `Caps (Tap)` to exit Insert mode. It will feel magical.

**When to use F13 now?** Reserve it for complex, two-handed chords like `Mod+Shift+Ctrl+S` where using a key on the function row is more comfortable.

---

### Phase 4: Mastery (Week 3+)

By now, the new movements should feel natural and significantly faster. You are now reaping the ergonomic and productivity benefits.

- **Your F13 usage should be <5%** of what it was.
- You no longer think about where the arrow keys are.
- You can't imagine going back to the old, slower way.

---

## Troubleshooting

- **`Caps Lock` isn't working right:**
  - **99% of the time, this is a firmware issue.** Ensure your Caps Lock key is sending a simple `KC_CAPS` and not a layer-tap key like `LT(...)`. See the [firmware guide](keyboard-firmware-update.md).
  - Restart the `keyd` service: `sudo systemctl restart keyd`.

- **`Caps Tap` is too sensitive/slow:**
  - You can adjust the timing. In `modules/nixos/system/keyd.nix`, add `overload_tap_timeout = 250;` (or your preferred value in ms) under the `settings` block.

- **Right Alt conflicts with special characters (AltGr):**
  - The `nav` layer was intentionally put on `rightalt` to avoid this. If you still have issues, you can move the layer to a different key (e.g., `rightctrl = "layer(nav)"`) in `keyd.nix`.

---

**You got this!** The first week requires conscious effort, but the payoff is a faster, healthier, and more comfortable computing experience.