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
  # Steam VR support - configure Steam FHS for OpenXR
  # This overrides the gaming module's Steam package to add VR-specific configuration
  programs.steam.package = lib.mkIf (config.host.features.gaming.steam or false) (
    pkgs.steam.override {
      extraProfile = ''
        # Fixes timezones in VRChat and Resonite
        # These social VR apps read TZ and can show incorrect times
        unset TZ

        # Allows OpenXR runtime to be discovered by sandboxed Steam games
        # Without this, Steam's pressure-vessel container cannot find Monado
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      '';
    }
  );
}
