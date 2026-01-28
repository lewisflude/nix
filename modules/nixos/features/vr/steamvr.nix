# SteamVR Configuration (Fallback for 32-bit VR games)
# Required for games like Half Life 2 VR that don't work with WiVRn
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf (cfg.enable && cfg.steamvr) {
  # SteamVR support for 32-bit VR games
  # Note: WiVRn doesn't support 32-bit executables (e.g., Half Life 2 VR)
  # SteamVR is needed as a fallback for these games

  # Install SteamVR dependencies
  environment.systemPackages = [
    # SteamVR itself is installed via Steam client
    # These are the system-level dependencies needed
  ];

  # Ensure 32-bit graphics drivers are available (already in graphics.nix)
  # hardware.graphics.enable32Bit = true;

  # Note: SteamVR must be installed through the Steam client
  # It cannot be packaged directly in NixOS due to its proprietary nature
  # SteamVR async reprojection works without additional capabilities

  assertions = [
    {
      assertion = cfg.steamvr -> config.host.features.gaming.steam;
      message = "SteamVR requires Steam to be enabled (features.gaming.steam = true)";
    }
  ];
}
