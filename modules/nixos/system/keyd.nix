# /home/lewis/.config/nix/modules/nixos/system/keyd.nix
#
# Ergonomic Hybrid Keyboard Configuration (v2.0)
#
# Combines the best ergonomic practices for a high-efficiency workflow:
# 1. Caps Lock -> Primary Super (overloaded with Escape) for home row access.
# 2. F13 -> Backup Super for complex, two-handed shortcuts.
# 3. Right Alt -> Navigation layer for OS-wide, Vim-style text editing.
#
_: {
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*"];
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
          # PRIMARY: Caps as Super (most ergonomic)
          # Hold for Super (meta), Tap for Escape.
          capslock = "overload(meta, esc)";

          # BACKUP: F13 also maps to Super
          f13 = "leftmeta";

          # SCREENSHOT: F14 produces Print Screen
          f14 = "print";

          # KVM SWITCHING: F15 produces Scroll Lock
          f15 = "scrolllock";

          # NAVIGATION: Right Alt activates the 'nav' layer
          rightalt = "layer(nav)";

          # WKL-style swap for Linux: map Left Alt -> Left Meta (Super)
          # Keep Ctrl as Ctrl; keep Right Alt reserved for nav layer.
          leftalt = "leftmeta";
        };

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
