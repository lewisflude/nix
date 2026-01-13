{
  config,
  lib,
  pkgs,
  constants,
  qbittorrentCfg,
  webUI,
  ...
}:
with lib;
let
  # Import config modules
  webUIConfig = import ./webui.nix {
    inherit
      config
      lib
      pkgs
      qbittorrentCfg
      webUI
      ;
  };
  bittorrentConfig = import ./bittorrent.nix {
    inherit lib qbittorrentCfg;
    webUICfg = webUIConfig.webUICfg;
  };
  serviceConfig = import ./service.nix {
    inherit
      config
      lib
      pkgs
      constants
      qbittorrentCfg
      webUI
      ;
    webUICfg = webUIConfig.webUICfg;
    preferencesCfg = bittorrentConfig.preferencesCfg;
    bittorrentSession = bittorrentConfig.bittorrentSession;
  };
in
mkMerge [
  (removeAttrs webUIConfig [ "webUICfg" ])
  serviceConfig
]
