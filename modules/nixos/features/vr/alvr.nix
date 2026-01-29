# ALVR Wireless VR Streaming Configuration
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf (cfg.enable && cfg.alvr.enable) {
  # ALVR wireless VR streaming configuration
  # Uses SteamVR as the OpenVR runtime (unlike WiVRn which uses Monado)
  programs.alvr = {
    enable = true;
    openFirewall = cfg.alvr.openFirewall;
  };

  # ALVR systemd service configuration
  systemd.user.services.alvr = lib.mkIf cfg.alvr.autoStart {
    wantedBy = [ "default.target" ];
  };

  # Note: ALVR uses SteamVR, so steamvr feature should be enabled
  # See: modules/nixos/features/vr/steamvr.nix
}
