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
    inherit (webUIConfig) webUICfg;
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
    inherit (webUIConfig) webUICfg;
    inherit (bittorrentConfig) preferencesCfg;
    inherit (bittorrentConfig) bittorrentSession;
  };
in
mkMerge [
  (removeAttrs webUIConfig [ "webUICfg" ])
  serviceConfig
]
