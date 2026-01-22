{
  lib,
  packageSets,
  ...
}:
let
  featureBuilders = {

    mkSystemPackages =
      {
        cfg,
        pkgs,
      }:
      lib.concatLists [

        (lib.optionals (cfg.buildTools or false) packageSets.buildTools)

        (lib.optionals (cfg.git or false) [ pkgs.git ])

        (lib.optionals (cfg.rust or false) packageSets.rustToolchain)

        (lib.optionals (cfg.python or false) (packageSets.pythonToolchain pkgs))

        (lib.optionals (cfg.go or false) packageSets.goToolchain)

        (lib.optionals (cfg.node or false) (packageSets.nodeToolchain pkgs))

        (lib.optionals (cfg.lua or false) packageSets.luaToolchain)

        (lib.optionals (cfg.java or false) [ pkgs.jdk ])

        (lib.optionals (cfg.nix or false) packageSets.nixTools)

        (lib.optionals (cfg.docker or false) packageSets.dockerTools)

        (lib.optionals (cfg.kubernetes or false) packageSets.kubernetesTools)

        (lib.optionals (cfg.vscode or false) packageSets.editors.vscode)
        (lib.optionals (cfg.neovim or false) packageSets.editors.neovim)
        (lib.optionals (cfg.helix or false) packageSets.editors.helix)
      ];

    mkHomePackages =
      {
        cfg,
        pkgs,
      }:
      packageSets.devUtilities
      ++ lib.optionals (cfg.debugTools or false) packageSets.debugTools

      ++ lib.optionals (cfg.buildTools or false) packageSets.buildTools

      # Note: delta and git-lfs are handled via programs.delta and programs.git.lfs
      # in home/common/git.nix, so they don't need to be installed here

      ++ lib.optionals (cfg.rust or false) packageSets.rustToolchain

      ++ lib.optionals (cfg.python or false) (packageSets.pythonToolchain pkgs)

      ++ lib.optionals (cfg.go or false) packageSets.goToolchain

      ++ lib.optionals (cfg.node or false) (packageSets.nodeToolchain pkgs)

      ++ lib.optionals (cfg.lua or false) packageSets.luaToolchain

      ++ lib.optionals (cfg.java or false) [ pkgs.jdk ]

      ++ lib.optionals (cfg.nix or false) (packageSets.nixTools ++ packageSets.languageFormatters.general)

      # Docker tools only on Linux (daemon requires system-level config)
      ++ lib.optionals (cfg.docker or false && pkgs.stdenv.isLinux) packageSets.dockerTools

      ++ lib.optionals (cfg.kubernetes or false) packageSets.kubernetesTools

      ++ lib.optionals (cfg.vscode or false) packageSets.editors.vscode
      ++ lib.optionals (cfg.neovim or false) packageSets.editors.neovim
      ++ lib.optionals (cfg.helix or false) packageSets.editors.helix;

    mkShellPackages =
      {
        cfg,
        pkgs,
      }:
      lib.concatLists [

        (lib.optionals (cfg.rust or false) packageSets.rustToolchain)

        (lib.optionals (cfg.python or false) [
          (pkgs.python3.withPackages (python-pkgs: [
            python-pkgs.pip
            python-pkgs.virtualenv
            python-pkgs.pytest
            python-pkgs.black
            python-pkgs.isort
            python-pkgs.mypy
            python-pkgs.ruff
          ]))
        ])

        (lib.optionals (cfg.go or false) packageSets.goToolchain)

        (lib.optionals (cfg.node or false) [
          pkgs.nodejs
        ])
      ];

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
