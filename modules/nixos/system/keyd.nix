# /home/lewis/.config/nix/modules/nixos/system/keyd.nix
#
# WKL F13 TKL Keyboard Configuration for nixOS
#
# Matches the keyboard-keymap.md specification:
# - Caps Lock: Control (from firmware, keyd passes through)
# - Left/Right Alt: Super (for window manager)
# - Left/Right Ctrl: Alt (for editor/terminal shortcuts)
# - F13: Focus Terminal
# - Print Screen: Focus Browser
#
# Device-specific configuration: Only applies to MNK88 keyboard
# This prevents remapping from affecting other keyboards
#
_: {
  services.keyd = {
    enable = true;
    keyboards.mnk88 = {
      # MNK88 keyboard IDs: vendor=19280 (0x4b50), product=34816 (0x8800)
      ids = ["4b50:8800"];
      settings = {
        # Global timing configuration
        # Based on research: 200ms balances false positives/negatives
        # (MacKenzie, 1992; Soukoreff & MacKenzie, 2004)
        global = {
          # Tap/hold threshold: Time window to distinguish tap from hold
          # - 150ms: Fast typers, may cause accidental holds
          # - 200ms: Recommended default for most users
          # - 250ms: Slower/more deliberate typers, reduces false taps
          # - 300ms: Users with motor control considerations
          overload_tap_timeout = 200;
        };

        main = {
          # Caps Lock: Map to Control (firmware now sends KC_CAPS)
          # This allows keyd to distinguish between Caps Lock and physical Control keys
          capslock = "leftcontrol";

          # WKL Modifier Swaps (matching macOS Karabiner config)
          # Alt keys become Super (for window manager)
          leftalt = "leftmeta";
          rightalt = "rightmeta";

          # Ctrl keys become Alt (for editor/terminal shortcuts)
          leftcontrol = "leftalt";
          rightcontrol = "rightalt";
        };

        # Optional: Navigation layer (can be removed if not needed)
        # Access via a dedicated key if desired
        nav = {
          # Vim-style arrows
          h = "left";
          j = "down";
          k = "up";
          l = "right";

          # Word-wise navigation (like Vim's w and b)
          w = "C-right"; # Word forward (Ctrl+Right)
          b = "C-left"; # Word backward (Ctrl+Left)

          # Page/line navigation
          u = "pagedown"; # Page down (mnemonic: Under)
          i = "pageup"; # Page up (mnemonic: up/In)
          y = "home"; # Line start (mnemonic: Yank to start)
          o = "end"; # Line end (mnemonic: Other end)

          # Editing shortcuts (using Ctrl/Meta combinations)
          # Note: Using C- prefix for control key
          c = "C-c"; # Copy
          v = "C-v"; # Paste
          x = "C-x"; # Cut
          z = "C-z"; # Undo
          s = "C-s"; # Save
          f = "C-f"; # Find
          d = "delete"; # Delete forward

          # Media controls (F1-F10 in nav layer)
          f1 = "brightnessdown";
          f2 = "brightnessup";
          f5 = "volumedown";
          f6 = "volumeup";
          f7 = "previoussong";
          f8 = "playpause";
          f9 = "nextsong";
          f10 = "mute";
        };
      };
    };
  };

  # Ensure keyd starts early in the boot process
  systemd.services.keyd = {
    wantedBy = ["sysinit.target"];
    # Ensures keyd runs before the graphical login manager
    before = ["display-manager.service"];
  };
}
