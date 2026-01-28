# Apogee USB Audio Reconnection - Simple manual command
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.media.audio;
in
{
  config = mkIf (pkgs.stdenv.isDarwin && cfg.enable) {
    # Simple script to reset CoreAudio after KVM switch
    # Just run: apogee-reconnect
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "apogee-reconnect" ''
        echo "Resetting CoreAudio..."
        sudo killall coreaudiod
        sleep 1
        echo "Done! Apogee should be available now."
      '')
    ];
  };
}
