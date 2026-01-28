{
  lib,
  packageSets,
  ...
}:
let
  # Generic helper to build package lists from feature flags
  # Handles both static package lists and functions that need pkgs
  mkPackagesFromFeatures =
    {
      cfg,
      pkgs,
      features,
    }:
    lib.concatLists (
      lib.mapAttrsToList (
        name: packages:
        lib.optionals (cfg.${name} or false) (
          if builtins.isFunction packages then packages pkgs else packages
        )
      ) features
    );

  featureBuilders = {

    mkSystemPackages =
      { cfg, pkgs }:
      mkPackagesFromFeatures {
        inherit cfg pkgs;
        features = {
          buildTools = packageSets.buildTools;
          git = [ pkgs.git ];
          rust = packageSets.rustToolchain;
          python = packageSets.pythonToolchain;
          go = packageSets.goToolchain;
          node = packageSets.nodeToolchain;
          lua = packageSets.luaToolchain;
          java = [ pkgs.jdk ];
          nix = packageSets.nixTools;
          docker = packageSets.dockerTools;
          kubernetes = packageSets.kubernetesTools;
          vscode = packageSets.editors.vscode;
          neovim = packageSets.editors.neovim;
          helix = packageSets.editors.helix;
        };
      };

    mkHomePackages =
      { cfg, pkgs }:
      packageSets.devUtilities
      ++ mkPackagesFromFeatures {
        inherit cfg pkgs;
        features = {
          debugTools = packageSets.debugTools;
          buildTools = packageSets.buildTools;
          rust = packageSets.rustToolchain;
          python = packageSets.pythonToolchain;
          go = packageSets.goToolchain;
          node = packageSets.nodeToolchain;
          lua = packageSets.luaToolchain;
          java = [ pkgs.jdk ];
          nix = packageSets.nixTools ++ packageSets.languageFormatters.general;
          kubernetes = packageSets.kubernetesTools;
          vscode = packageSets.editors.vscode;
          neovim = packageSets.editors.neovim;
          helix = packageSets.editors.helix;
        };
      }
      # Docker tools only on Linux (daemon requires system-level config)
      ++ lib.optionals (cfg.docker or false && pkgs.stdenv.isLinux) packageSets.dockerTools;

    mkShellPackages =
      { cfg, pkgs }:
      mkPackagesFromFeatures {
        inherit cfg pkgs;
        features = {
          rust = packageSets.rustToolchain;
          python = [
            (pkgs.python3.withPackages (python-pkgs: [
              python-pkgs.pip
              python-pkgs.virtualenv
              python-pkgs.pytest
              python-pkgs.black
              python-pkgs.isort
              python-pkgs.mypy
              python-pkgs.ruff
            ]))
          ];
          go = packageSets.goToolchain;
          node = [ pkgs.nodejs ];
        };
      };

    mkDevEnvironment =
      cfg:
      lib.mkMerge [
        (lib.mkIf cfg.rust {
          RUST_BACKTRACE = "1";
        })
        (lib.mkIf cfg.go {
          GOPATH = "$HOME/go";
          GOBIN = "$HOME/go/bin";
        })
        (lib.mkIf cfg.node {
          NODE_OPTIONS = "--max-old-space-size=4096";
        })
        (lib.mkIf cfg.python {
          PYTHONPATH = "$HOME/.local/lib/python3.12/site-packages:$PYTHONPATH";
        })
      ];
  };
in
featureBuilders
