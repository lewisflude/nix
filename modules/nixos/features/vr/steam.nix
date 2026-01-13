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
        # Fixes timezones in VRChat and Resonite
        # These social VR apps read TZ and can show incorrect times
        # Source: https://lvra.gitlab.io/docs/distros/nixos/#vrchat--resonite
        unset TZ

        # Allow Steam's pressure-vessel container to discover OpenXR runtimes
        # This enables VR games to connect to Monado/WiVRn inside the Steam FHS
        # CRITICAL: Required for all OpenXR apps running under Steam
        # Source: https://lvra.gitlab.io/docs/distros/nixos/#steam-games-and-openvr-apps
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      '';
    }
  );
}
