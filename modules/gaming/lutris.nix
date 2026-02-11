# Lutris Gaming Module - Dendritic Pattern
# Open source gaming platform with declarative Wine/Proton runner configuration
_: {
  flake.modules.homeManager.lutris =
    {
      pkgs,
      osConfig ? { },
      ...
    }:
    {
      programs.lutris = {
        enable = true;
        # Wine packages for game compatibility
        winePackages = [ pkgs.wineWowPackages.stagingFull ];
        # Proton packages for umu-launcher
        protonPackages = [ pkgs.proton-ge-bin ];
        # Steam integration (if Steam is enabled at system level)
        steamPackage = osConfig.programs.steam.package or null;
        # Extra packages commonly needed by games
        extraPackages = [
          pkgs.winetricks
          pkgs.gamemode
        ];
      };
    };
}
