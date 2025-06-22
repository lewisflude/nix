{ ... }: {
  services.mako = {
    enable = true;
    actions = true;
    anchor = "top-right";
    backgroundColor = "#24273a";
    borderColor = "#b7bdf8";
    borderRadius = 8;
    borderSize = 1;
    defaultTimeout = 5000;
    font = "Iosevka Nerd Font 11";
    height = 110;
    icons = true;
    iconPath = "/run/current-system/sw/share/icons/Papirus";
    layer = "overlay";
    margin = "10";
    markup = true;
    maxIconSize = 48;
    maxVisible = 5;
    padding = "10";
    progressColor = "over #363a4f";
    textColor = "#cad3f5";
    width = 350;
    
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