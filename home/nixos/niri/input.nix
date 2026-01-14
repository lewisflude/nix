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

    # Focus follows mouse for faster workflow
    # max-scroll-amount: won't focus if it would scroll view more than 10% of screen width
    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "10%";
    };

    # Warp mouse cursor to window when focused via keyboard
    # Complements focus-follows-mouse for keyboard-driven navigation
    warp-mouse-to-focus = {
      enable = true;
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
