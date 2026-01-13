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
  # PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES is handled by services.wivrn.steam.importOXRRuntimes
  # in wivrn.nix, so we only need to configure VR-specific environment variables here
  programs.steam.package = lib.mkIf (config.host.features.gaming.steam or false) (
    pkgs.steam.override {
      extraProfile = ''
        # Fixes timezones in VRChat and Resonite
        # These social VR apps read TZ and can show incorrect times
        unset TZ
      '';
    }
  );
}
