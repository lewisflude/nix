# SteamVR Support Configuration
{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf (cfg.enable && cfg.steamvr) {
  # SteamVR support (not recommended on Wayland)
  # SteamVR works poorly on Wayland and is proprietary
  # Monado + OpenComposite provides better performance and compatibility
  # This option should generally be disabled on NixOS
  # SteamVR is installed via Steam, so no additional packages needed
  # Just ensure Steam is enabled in gaming configuration
  assertions = [
    {
      assertion = config.host.features.gaming.steam or false;
      message = "SteamVR requires Steam to be enabled (host.features.gaming.steam = true)";
    }
  ];
}
