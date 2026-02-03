# Development tools feature module
# Dendritic pattern: Uses osConfig instead of systemConfig
{
  lib,
  pkgs,
  osConfig ? {},
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.host.features.development or {};
  packageSets = import ../../../../lib/package-sets.nix {
    inherit pkgs;
  };
  featureBuilders = import ../../../../lib/feature-builders.nix {
    inherit lib packageSets;
  };
in
{
  imports = [
    ./version-control.nix
    ./language-tools.nix
  ];

  config = mkIf (cfg.enable or false) {
    home.packages = featureBuilders.mkHomePackages {
      inherit cfg pkgs;
    };

    programs = {
      git = mkIf cfg.git {
        enable = true;
        lfs.enable = true;
      };
      neovim = mkIf cfg.neovim {
        enable = true;
        viAlias = true;
        vimAlias = true;
      };
    };

  };
}
