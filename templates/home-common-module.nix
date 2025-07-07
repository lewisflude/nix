# Template for home/common/ - Cross-platform Home Manager modules only
{
  pkgs,
  lib,
  system,
  config,
  ...
}:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
in
{
  # Cross-platform Home Manager configuration only
  # Platform-specific logic should be moved to home/darwin/ or home/nixos/
  
  # Cross-platform user packages
  home.packages = with pkgs; [
    # Packages that work identically on all platforms
    git
    curl
    jq
  ] ++ platformLib.platformPackages
    [
      # Linux-specific packages
      linux-specific-package
    ]
    [
      # Darwin-specific packages  
      darwin-specific-package
    ];

  # Cross-platform program configuration
  programs.example = {
    enable = true;
    
    settings = {
      # Cross-platform settings
      theme = "dark";
      editor = "vim";
    } // lib.optionalAttrs platformLib.isDarwin {
      # Darwin-specific settings (only when necessary)
      integration = "macos";
    } // lib.optionalAttrs platformLib.isLinux {
      # Linux-specific settings (only when necessary)
      integration = "systemd";
    };
  };

  # Cross-platform file configuration
  home.file.".example-config" = {
    text = ''
      # Cross-platform configuration file
      setting1=value1
      setting2=value2
    '';
  };

  # Use dynamic paths instead of hardcoded ones
  home.file."${platformLib.configDir config.home.username}/example/config.toml" = {
    text = ''
      config_dir = "${platformLib.configDir config.home.username}"
      data_dir = "${platformLib.dataDir config.home.username}"
      cache_dir = "${platformLib.cacheDir config.home.username}"
    '';
  };
}