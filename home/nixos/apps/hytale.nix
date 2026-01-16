{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.hytale-launcher;
in
{
  options.programs.hytale-launcher = {
    enable = lib.mkEnableOption "Hytale launcher";
  };

  config = lib.mkIf cfg.enable {
    # Use nix-flatpak's built-in bundle support
    services.flatpak.packages = [
      {
        appId = "com.hypixel.HytaleLauncher";
        sha256 = "1z5vnfkn61zlhir5pjsyr56bncf0hz99bjsaq7zgxc3g4bgdza5k";
        bundle = "${pkgs.fetchurl {
          url = "https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-latest.flatpak";
          sha256 = "1z5vnfkn61zlhir5pjsyr56bncf0hz99bjsaq7zgxc3g4bgdza5k";
        }}";
      }
    ];
  };
}
