{ pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    winetricks
    (wineWowPackages.staging.override {
      mingwSupport = true;
      vulkanSupport = true;
    })
    bottles
  ];
}
