# WKL F13 TKL Keymap: A Software Engineer's Layout (v2)

This document details an opinionated keymap for a WKL F13 TKL keyboard, designed for a software engineer who primarily uses macOS (nix-darwin) and nixOS, with a focus on ergonomics, productivity, and seamless context switching. Version 2 adds dedicated KVM switching macros.

## 1. Core Philosophy

This layout is built on four principles:

Ergonomic Control: The Caps Lock key is remapped to Control in the firmware, moving the most common modifier to the home row to reduce pinky strain.
Thumb-Driven Layers: The thumb is your strongest digit. The Spacebar becomes a "Mod-Tap" key, acting as Space when tapped and as a layer-access key ("Layer 1") when held.
OS-Level Modifiers: We solve the Cmd (macOS) vs. Ctrl (nixOS) problem at the operating system level, not in the firmware. This keeps the keyboard's logic clean and ensures native application behavior on both platforms.
Dedicated Macro Cluster: The top-right keys (F13, PrtSc, etc.) are re-purposed for high-frequency, workflow-specific tasks.

## 2. Prerequisites: Platform-Level Configuration

This is the most crucial step. The keyboard firmware will always send the same "standard" PC layout. Your operating systems will be configured to interpret these keys correctly.

### On macOS (nix-darwin)

Use services.karabiner-elements to swap the keys adjacent to the spacebar (Alt) with the corner keys (Ctrl).

```nix
# in your nix-darwin configuration.nix
services.karabiner-elements.enable = true;
services.karabiner-elements.extraConfig.profiles[0].complex_modifications.rules = [
  {
    description = "WKL Swap: Alt <-> Ctrl";
    manipulators = [
      # Left Side
      { type = "basic"; from = { key_code = "left_option"; };  to = [ { key_code = "left_command"; } ]; }
      { type = "basic"; from = { key_code = "left_control"; }; to = [ { key_code = "left_option"; } ]; }
      # Right Side
      { type = "basic"; from = { key_code = "right_option"; };  to = [ { key_code = "right_command"; } ]; }
      { type = "basic"; from = { key_code = "right_control"; }; to = [ { key_code = "right_option"; } ]; }
    ];
  }
];
```

Result on macOS:
Caps Lock: Control (from firmware)
Alt key (next to spacebar): Command (⌘)
Ctrl key (corner): Option (⌥)

### On nixOS

Use services.xserver.xkbOptions to perform a similar swap, making the Alt key act as Super (the "Windows" key) and the Ctrl key act as Alt.

```nix
# in your nixos configuration.nix
services.xserver = {
  enable = true;
  layout = "us";
  # Swaps Left Alt with Left Super, and Right Alt with Right Super.
  # We must also restore F13-F24, as XKB can map them to media keys.
  xkbOptions = "altwin:swap_alt_win,lv3:lalt_switch,misc:extend,lv5:ralt_switch_lock,misc:extend";
};
```

Result on nixOS:
Caps Lock: Control (from firmware)
Alt key (next to spacebar): Super (for window manager)
Ctrl key (corner): Alt (for editor/terminal shortcuts)

## 3. Firmware Keymap (QMK/VIA/Vial)

This is the logic to be flashed onto the keyboard itself.

### Base Layer (Layer 0)

This layer defines your standard typing experience and establishes the layer-tap triggers.

Caps Lock: KC_LCTL
Rationale: The cornerstone of the ergonomic layout. Control is now on the home row.
Spacebar: MT(MOD_L1, KC_SPC)
Rationale: A Mod-Tap key. Tapping gives Space. Holding activates Layer 1. Requires tuning the TAPPING_TERM to your typing speed.
Left Ctrl (1.5u): LT(MOD_L2, KC_LCTL)
Rationale: A Layer-Tap key. Tapping gives Left Control (which becomes Opt/Alt via the OS config). Holding activates Layer 2.
Left Alt (1.5u): KC_LALT
Rationale: A standard key. (Becomes Cmd/Super via the OS config).
Right Alt (1.5u): KC_RALT
Right Ctrl (1.5u): KC_RCTL

### Dedicated Macro Cluster (Base Layer)

The top-right cluster is mapped to high-frequency, cross-platform macros.

| Key | Macro Function | Rationale & Implementation |
| :--- | :--- | :--- |
| **`F13`** | **Focus Terminal** | Your primary context switch. Use OS-level tools (Karabiner, Hammerspoon, WM script) to bind F13 to "Focus or Launch Ghostty." |
| **`Print Screen`** | **Focus Browser** | Your secondary context switch. Bind PrtSc to "Focus or Launch Browser." |
| **`Scroll Lock`** | **Git Push** | Your most common Git action. Map to a macro for "Git: Push" in the VSCode palette (e.g., Cmd+Shift+P, "Git: Push", Enter). |
| **`Pause/Break`** | **Reload Window** | Your "panic button." Map to the VSCode command Developer: Reload Window (e.g., Cmd+Shift+P, "Reload Window", Enter). |

### Layer 1: Productivity Layer (Hold Spacebar)

This layer is for navigation and Git actions, keeping your hands on the home row.

| Key(s) | Function | Rationale |
| :--- | :--- | :--- |
| H, J, K, L | Left, Down, Up, Right | Vim/Helix-style navigation. |
| Y, U, I, O | Home, Page Down, Page Up, End | Logical cluster for document navigation. |
| P | Macro: Git: Pull | Home-row access to your Git workflow. |
| S | Macro: Git: Stash | Home-row access to your Git workflow. |
| C | Macro: Git: Commit | Home-row access to your Git workflow. |

### Layer 2: System Layer (Hold Left Ctrl)

This layer handles both window management (via the arrow cluster) and KVM device switching (via the number row).

#### Window Management (Arrow Cluster)

| Key(s) | Function | Rationale |
| :--- | :--- | :--- |
| Physical Up Arrow | Maximize Window | Fast, full-screen focus. |
| Physical Down Arrow | Minimize / Center Window | Get a window out of the way or reset its position. |
| Physical Left Arrow | Tile Window to Left 50% | Essential for side-by-side work. |
| Physical Right Arrow | Tile Window to Right 50% | Essential for side-by-side work. |

(Implementation: These keys should send macro combinations that your OS window manager (rectangle on macOS, your WM on nixOS) understands for tiling.)

#### KVM Switching (Number Row)

| Key(s) | Function | Rationale & Implementation |
| :--- | :--- | :--- |
| 1, 2, 3... | Switch to KVM Device 1, 2, 3... | A single, ergonomic chord for fast device switching. Implement as a macro in VIA/Vial: {KC_SLCK}{KC_SLCK}{KC_1} for Device 1, and so on. |

## 4. Quick Reference: The Complete Map

| Key | Base Layer (Tap) | Layer 1 (Hold Space) | Layer 2 (Hold L-Ctrl) |
| :--- | :--- | :--- | :--- |
| Caps Lock | Left Control | (transparent) | (transparent) |
| L-Ctrl (1.5u) | L-Ctrl (becomes Opt/Alt) | (transparent) | LAYER 2 TRIGGER |
| L-Alt (1.5u) | L-Alt (becomes Cmd/Super) | (transparent) | (transparent) |
| Spacebar | Space | LAYER 1 TRIGGER | (transparent) |
| H, J, K, L | h, j, k, l | Arrow Keys | (transparent) |
| P, S, C | p, s, c | Git Pull, Stash, Commit | (transparent) |
| F13 | Focus Terminal | (transparent) | (transparent) |
| Print Screen | Focus Browser | (transparent) | (transparent) |
| Scroll Lock | Git Push | (transparent) | (transparent) |
| Pause/Break | Reload Window | (transparent) | (transparent) |
| Arrow Keys | Arrow Keys | (transparent) | Window Tiling |
| Number Row | 1, 2, 3... | (transparent) | KVM Switch (Device 1, 2, 3...) |
