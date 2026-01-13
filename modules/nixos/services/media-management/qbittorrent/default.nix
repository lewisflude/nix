{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
with lib;
let
  cfg = config.host.services.mediaManagement;
  qbittorrentCfg = cfg.qbittorrent;
  inherit (qbittorrentCfg) webUI;
in
{
  imports = [
    # Import options
    (import ./options/default.nix {
      inherit lib constants;
    })
  ];

  # Import config (only when enabled)
  config = mkIf (cfg.enable && qbittorrentCfg.enable) (
    import ./config/default.nix {
      inherit
        config
        lib
        pkgs
        constants
        qbittorrentCfg
        webUI
        ;
    }
  );
}
