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
    (import ./options/default.nix { inherit lib constants; })
  ];

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
