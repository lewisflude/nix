_: {
  services.mako = {
    enable = true;
    settings = {
      # Enhanced functionality
      actions = true;
      anchor = "top-right";
      border-radius = 8;
      border-size = 2;
      default-timeout = 5000;
      font = "Iosevka Nerd Font 11";
      height = 110;
      icons = true;
      icon-path = "/run/current-system/sw/share/icons/Papirus";
      layer = "overlay";
      margin = "10,10,0,0";
      markup = true;
      max-icon-size = 48;
      max-visible = 5;
      padding = "12";
      width = 400;

      # Interaction improvements
      group-by = "app-name";
      sort = "-time";
      on-button-left = "dismiss";
      on-button-middle = "none";
      on-button-right = "dismiss-all";
      on-touch = "dismiss";
    };

    extraConfig = ''
      [urgency=low]
      default-timeout=3000

      [urgency=normal]
      default-timeout=5000

      [urgency=high]
      default-timeout=0

      [category=mpd]
      default-timeout=3000
      group-by=category

      [summary~=".*[Bb]attery.*"]
      default-timeout=8000
    '';
  };
}
