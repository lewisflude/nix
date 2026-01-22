# Niri Input Configuration
_: {
  input = {
    keyboard = {
      xkb = {
        layout = "us";
      };

      # Key repeat settings (600ms delay before repeat, 25 keys/sec when repeating)
      repeat-delay = 600;
      repeat-rate = 25;
    };

    # Focus follows mouse for "tape scrolling" metaphor
    # max-scroll-amount = "0%": instant focus without delay
    # In a scrolling UI, the cursor acts as a "read head"
    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "0%";
    };

    # Warp mouse disabled - prevents disorientation during keyboard navigation
    # Per guide: "Disable warping - it disorients the user"
    warp-mouse-to-focus = {
      enable = false;
    };

    # Quick workspace switching - press same keybind twice to toggle back
    workspace-auto-back-and-forth = true;

    mouse = {
      natural-scroll = true;
      # Flat profile disables pointer acceleration for consistent 1:1 movement
      accel-profile = "flat";
      scroll-factor = 1.0;
    };
  };
}
