# Niri Input Configuration
_: {
  input = {
    keyboard = {
      xkb = {
        layout = "us";
      };

      repeat-delay = 600;
      repeat-rate = 25;
    };

    # Focus follows mouse for faster workflow
    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "10%";
    };

    # Warp mouse to focused window for even faster navigation
    warp-mouse-to-focus = {
      enable = true;
    };

    # Quick workspace switching - go back to previous workspace with same keybind
    workspace-auto-back-and-forth = true;

    mouse = {
      natural-scroll = true;
      accel-speed = 0.2;
      accel-profile = "flat";
      scroll-factor = 1.0;
    };

    touchpad = {
      tap = true;
      natural-scroll = true;
      accel-speed = 0.3;
      accel-profile = "adaptive";
    };
  };
}
