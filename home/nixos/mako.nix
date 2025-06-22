{ ... }: {
  services.mako = {
    enable = true;
    settings = {
      actions = true;
      anchor = "top-right";
      background-color = "#24273a";
      border-color = "#b7bdf8";
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
      progress-color = "over #363a4f";
      text-color = "#cad3f5";
      width = 350;
    };
    
    extraConfig = ''
      [urgency=low]
      border-color=#a6da95
      default-timeout=2000
      
      [urgency=normal]
      border-color=#8aadf4
      default-timeout=5000
      
      [urgency=high]
      border-color=#ed8796
      default-timeout=0
      
      [category=mpd]
      default-timeout=2000
      group-by=category
    '';
  };
}