{ pkgs, ... }: {
  services.solaar = {
    enable = true;
    package = pkgs.solaar;
    window = "hide";
    batteryIcons = "regular";
    extraArgs = "";
  };
  services.ratbagd.enable = true;
}
