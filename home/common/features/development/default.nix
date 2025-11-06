# Home Manager development feature module (cross-platform)
# Controlled by host.features.development.*
# Provides user-level development packages for both NixOS and Darwin
{
  lib,
  pkgs,
  host,
  hostSystem,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = host.features.development;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  packageSets = import ../../../../lib/package-sets.nix {
    inherit pkgs;
    inherit (platformLib) versions;
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
      inherit cfg pkgs platformLib;
    };

    # Program configurations
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
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

    # Helix is provided by the chaotic module
    # See: https://github.com/chaotic-cx/nyx/tree/main/homeModules
  };
}
