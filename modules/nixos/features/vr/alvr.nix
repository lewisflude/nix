# ALVR (Air Light VR) Configuration
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf (cfg.enable && cfg.alvr) {
  # ALVR (Air Light VR) - Alternative wireless VR streaming
  # Note: ALVR requires SteamVR, so it's incompatible with Monado-only setups
  # This option should be disabled when using WiVRn + Monado
  environment.systemPackages = [ pkgs.alvr ];

  # ALVR firewall ports (if openFirewall equivalent existed)
  # These ports are used for ALVR streaming protocol
  networking.firewall = {
    allowedTCPPorts = [
      9943 # ALVR web server
      9944 # ALVR streaming
    ];
    allowedUDPPorts = [
      9943
      9944
    ];
  };
}
