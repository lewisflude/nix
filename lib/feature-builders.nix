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
      with pkgs;
      lib.concatLists [

        (lib.optionals (cfg.buildTools or false) packageSets.buildTools)

        (lib.optionals (cfg.git or false) packageSets.gitTools)

        (lib.optionals (cfg.rust or false) packageSets.rustToolchain)

        (lib.optionals (cfg.python or false) (packageSets.pythonToolchain pkgs))

        (lib.optionals (cfg.go or false) packageSets.goToolchain)

        (lib.optionals (cfg.node or false) (packageSets.nodeToolchain pkgs))

        (lib.optionals (cfg.lua or false) packageSets.luaToolchain)

        (lib.optionals (cfg.java or false) packageSets.javaToolchain)

        (lib.optionals (cfg.nix or false) packageSets.nixTools)

        (lib.optionals (cfg.docker or false) packageSets.dockerTools)

        (lib.optionals (cfg.kubernetes or false) packageSets.kubernetesTools)

        (lib.optionals (cfg.vscode or false) (packageSets.editors.vscode pkgs))
        (lib.optionals (cfg.neovim or false) (packageSets.editors.neovim pkgs))
        (lib.optionals (cfg.helix or false) (packageSets.editors.helix pkgs))
      ];

    mkHomePackages =
      {
        cfg,
        pkgs,
        platformLib,
      }:
      with pkgs;
      packageSets.devUtilities
      ++ packageSets.debugTools

      ++ lib.optionals (cfg.buildTools or false) packageSets.buildTools

      ++ lib.optionals (cfg.git or false) [
        delta
        git-lfs
      ]

      ++ lib.optionals (cfg.rust or false) packageSets.rustToolchain

      ++ lib.optionals (cfg.python or false) (packageSets.pythonToolchain pkgs)

      ++ lib.optionals (cfg.go or false) packageSets.goToolchain

      ++ lib.optionals (cfg.node or false) (packageSets.nodeToolchain pkgs)

      ++ lib.optionals (cfg.lua or false) packageSets.luaToolchain

      ++ lib.optionals (cfg.java or false) packageSets.javaToolchain

      ++ lib.optionals (cfg.nix or false) (packageSets.nixTools ++ packageSets.languageFormatters.general)

      ++ lib.optionals (cfg.docker or false) (platformLib.platformPackages packageSets.dockerTools [ ])

      ++ lib.optionals (cfg.kubernetes or false) packageSets.kubernetesTools

      ++ lib.optionals (cfg.vscode or false) (packageSets.editors.vscode pkgs)
      ++ lib.optionals (cfg.neovim or false) (packageSets.editors.neovim pkgs)
      ++ lib.optionals (cfg.helix or false) (packageSets.editors.helix pkgs);

    mkShellPackages =
      {
        cfg,
        pkgs,
        versions,

        pythonVersion ? versions.python,
        nodeVersion ? versions.nodejs,
      }:
      with pkgs;
      lib.concatLists [

        (lib.optionals (cfg.rust or false) packageSets.rustToolchain)

        (lib.optionals (cfg.python or false) (
          let
            python = pkgs.${pythonVersion};
          in
          [
            (python.withPackages (
              python-pkgs: with python-pkgs; [
                pip
                virtualenv
                pytest
                black
                isort
                mypy
                ruff
              ]
            ))

            poetry
          ]
        ))

        (lib.optionals (cfg.go or false) packageSets.goToolchain)

        (lib.optionals (cfg.node or false) [
          pkgs.${nodeVersion}
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
