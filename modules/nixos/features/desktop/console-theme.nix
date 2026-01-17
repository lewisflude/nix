{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Console theming is handled by Signal's NixOS modules (theming.signal.nixos.boot.console)
    # This module just ensures a good font is available
    console = {
      # Use a clean, readable font (Terminus is a good monospace font for console)
      font = "ter-v22n";
      packages = [ pkgs.terminus_font ];
      earlySetup = true;
    };
  };
}
