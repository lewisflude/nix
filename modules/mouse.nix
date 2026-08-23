# Mouse hardware support (Logitech, gaming mice)
_: {
  flake.modules.nixos.mouse = {
    # Solaar ships in nixpkgs as programs.solaar (upstreamed from the
    # Svenum/Solaar-Flake input this used to pull in — keeping both declared
    # programs.solaar twice and broke evaluation).
    programs.solaar = {
      enable = true;
      userService = {
        enable = true;
        window = "hide";
        batteryIcons = "regular";
      };
    };
    # The nixpkgs unit orders itself only After=dbus.service and otherwise
    # relies on WantedBy=graphical-session.target, which adds no ordering at
    # all. Under uwsm that means solaar is launched the instant the session
    # envelope target starts (2026-08-23 13:57:56.216) — before niri has created
    # the Wayland socket and before uwsm has exported WAYLAND_DISPLAY/DISPLAY
    # into the user manager. Solaar's GTK front-end falls back to X11, finds
    # DISPLAY empty, and exits 1 with `cannot open display:`; Restart=on-failure
    # papers over it five seconds later, so the only symptom is one failed unit
    # per login. uwsm reaches graphical-session.target only once the compositor
    # has notified readiness and the environment is exported, so ordering after
    # it removes the failed first start. No deadlock: WantedBy puts solaar in
    # the target's Wants, After merely sequences it once the target is reached.
    systemd.user.services.solaar.after = [ "graphical-session.target" ];

    services.ratbagd.enable = true;
  };
}
