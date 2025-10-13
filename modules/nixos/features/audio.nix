# Audio feature module for NixOS
# Controlled by host.features.audio.*
# Note: This module focuses on music production features.
# Basic PipeWire audio is configured in modules/nixos/desktop/audio/
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.audio;
in {
  config = mkIf cfg.enable {
    # Enable musnix for real-time audio optimization
    musnix = {
      enable = true;
      # Real-time kernel and optimizations (only if realtime flag is set)
      kernel = mkIf cfg.realtime {
        realtime = true;
        packages = pkgs.linuxPackages_rt_latest;
      };
      rtirq.enable = cfg.realtime;
    };

    # Enable rtkit for real-time scheduling
    security.rtkit.enable = true;

    # Audio production packages
    environment.systemPackages = with pkgs;
      mkIf cfg.production [
        ardour
        audacity
        helm
        lsp-plugins
        zyn-fusion
      ];

    # Ensure user is in audio group
    users.users.${config.host.username}.extraGroups =
      optional cfg.enable "audio";
  };
}
