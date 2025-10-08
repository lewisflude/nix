{ pkgs
, lib
, config
, ...
}: {
  environment.systemPackages = with pkgs; [
    wofi
    # sway # You can keep this if you want it as a fallback
    gtk4
    uwsm # Needed for uwsm desktop entries to be available
  ];

  # Make wayland sessions available to greetd
  environment.pathsToLink = [ "/share/wayland-sessions" ];

  time.timeZone = "Europe/London";

  # This part is correct and doesn't need to change.
  programs.niri.enable = true;

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      niri = {
        prettyName = "Niri (UWSM)";
        comment = "Niri compositor managed by UWSM";
        binPath = pkgs.writeShellScript "niri" ''
          ${lib.getExe config.programs.niri.package} --session
        '';
      };
    };
  };

  services = {
    greetd = {
      enable = true;
      settings = {
        # This is the greeter itself. It will now show a session list.
        # Your original config for this was already correct.
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --time-format '%I:%M %p | %a • %h | %F'";
          user = "greeter";
        };

        # REMOVE the `initial_session` block entirely.
        # The greeter will now handle launching the user's chosen session.
      };
    };

    # Color management daemon for ICC profile support
    colord.enable = true;
  };
}
