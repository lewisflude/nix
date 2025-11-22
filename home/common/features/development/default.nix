{
  lib,
  pkgs,
  systemConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = systemConfig.host.features.development;
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

  config = mkIf cfg.enable {
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
