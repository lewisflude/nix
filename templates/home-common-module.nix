{
  pkgs,
  lib,
  system,
  config,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  home = {
    packages = [
      pkgs.git
      pkgs.curl
      pkgs.jq
    ]
    ++
      platformLib.platformPackages
        [
          pkgs.linux-specific-package
        ]
        [
          pkgs.darwin-specific-package
        ];
    file = {
      ".example-config" = {
        text = ''
          setting1=value1
          setting2=value2
        '';
      };
      "${platformLib.configDir config.home.username}/example/config.toml" = {
        text = ''
          config_dir = "${platformLib.configDir config.home.username}"
          data_dir = "${platformLib.dataDir config.home.username}"
          cache_dir = "${platformLib.cacheDir config.home.username}"
        '';
      };
    };
  };
  programs.example = {
    enable = true;
    settings = {
      theme = "dark";
      editor = "vim";
    }
    // lib.optionalAttrs platformLib.isDarwin {
      integration = "macos";
    }
    // lib.optionalAttrs platformLib.isLinux {
      integration = "systemd";
    };
  };
}
