{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    wofi
    # sway # You can keep this if you want it as a fallback
    gtk4
  ];

  time.timeZone = "Europe/London";

  # This part is correct and doesn't need to change.
  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      niri = {
        prettyName = "Niri";
        comment = "Niri compositor managed by UWSM";
        binPath = "${config.programs.niri.package}/bin/niri-session";
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
  };
}
