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

        # Note: PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1 is handled by
        # services.wivrn.steam.importOXRRuntimes = true in wivrn.nix
        # No need to set it manually here
      '';

      # Add graphics libraries to Steam FHS environment for OpenXR/VR
      # Required for xrizer and OpenXR runtimes to access GPU
      extraLibraries =
        pkgs: with pkgs; [
          # OpenXR and Vulkan support
          openxr-loader
          vulkan-loader
          vulkan-validation-layers

          # OpenGL support
          libglvnd
          libGL

          # X11 support (some OpenVR games need this)
          xorg.libX11
          xorg.libXrandr
          xorg.libXi
        ];
    }
  );
}
