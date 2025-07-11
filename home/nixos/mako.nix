{ ... }: {
  services.mako = {
    enable = true;
    settings = {
      actions = true;
      anchor = "top-right";
      border-radius = 8;
      border-size = 1;
      default-timeout = 5000;
      font = "Iosevka Nerd Font 11";
      height = 110;
      icons = true;
      icon-path = "/run/current-system/sw/share/icons/Papirus";
      layer = "overlay";
      margin = "10";
      markup = true;
      max-icon-size = 48;
      max-visible = 5;
      padding = "10";
      width = 350;
    };
    
    extraConfig = ''
      [urgency=low]
      default-timeout=2000
      
      [urgency=normal]
      default-timeout=5000
      
      [urgency=high]
      default-timeout=0
      
      [category=mpd]
      default-timeout=2000
      group-by=category
    '';
  };
}