# Steam VR Integration Configuration
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf cfg.enable {
  # Steam VR support - configure Steam FHS for VR apps
  # Based on Linux VR Adventures Wiki: https://lvra.gitlab.io/docs/distros/nixos/
  programs.steam.package = lib.mkIf (config.host.features.gaming.steam or false) (
    pkgs.steam.override {
      extraProfile = ''
        # Fixes timezones on VRChat
        unset TZ
        # Allows Monado to be used
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      '';
    }
  );
}
