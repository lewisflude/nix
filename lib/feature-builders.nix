# Feature builders for composing features from package sets
# Pure functions that compose package sets based on feature configuration
{
  lib,
  packageSets,
  ...
}:
let
  featureBuilders = {
    # Build system-level packages from feature config
    mkSystemPackages =
      {
        cfg, # Feature config (e.g., config.host.features.development)
        pkgs, # Platform utilities (reserved for future use)
      }:
      with pkgs;
      lib.concatLists [
        # Build tools
        (lib.optionals (cfg.buildTools or false) packageSets.buildTools)
        # Git tools
        (lib.optionals (cfg.git or false) packageSets.gitTools)
        # Rust
        (lib.optionals (cfg.rust or false) packageSets.rustToolchain)
        # Python
        (lib.optionals (cfg.python or false) (packageSets.pythonToolchain pkgs))
        # Go
        (lib.optionals (cfg.go or false) packageSets.goToolchain)
        # Node.js
        (lib.optionals (cfg.node or false) (packageSets.nodeToolchain pkgs))
        # Lua
        (lib.optionals (cfg.lua or false) packageSets.luaToolchain)
        # Java
        (lib.optionals (cfg.java or false) packageSets.javaToolchain)
        # Nix
        (lib.optionals (cfg.nix or false) packageSets.nixTools)
        # Docker
        (lib.optionals (cfg.docker or false) packageSets.dockerTools)
        # Kubernetes
        (lib.optionals (cfg.kubernetes or false) packageSets.kubernetesTools)
        # Editors
        (lib.optionals (cfg.vscode or false) (packageSets.editors.vscode pkgs))
        (lib.optionals (cfg.neovim or false) (packageSets.editors.neovim pkgs))
        (lib.optionals (cfg.helix or false) (packageSets.editors.helix pkgs))
      ];

    # Build home-manager packages (includes dev utilities and debug tools)
    mkHomePackages =
      {
        cfg,
        pkgs,
        platformLib, # Platform utilities
      }:
      with pkgs;
      packageSets.devUtilities
      ++ packageSets.debugTools
      # Build tools
      ++ lib.optionals (cfg.buildTools or false) packageSets.buildTools
      # Git tools (delta and git-lfs only, git/gh are in core-tooling)
      ++ lib.optionals (cfg.git or false) [
        delta
        git-lfs
      ]
      # Rust
      ++ lib.optionals (cfg.rust or false) packageSets.rustToolchain
      # Python
      ++ lib.optionals (cfg.python or false) (packageSets.pythonToolchain pkgs)
      # Go
      ++ lib.optionals (cfg.go or false) packageSets.goToolchain
      # Node.js
      ++ lib.optionals (cfg.node or false) (packageSets.nodeToolchain pkgs)
      # Lua
      ++ lib.optionals (cfg.lua or false) packageSets.luaToolchain
      # Java
      ++ lib.optionals (cfg.java or false) packageSets.javaToolchain
      # Nix (includes additional tools)
      ++ lib.optionals (cfg.nix or false) (packageSets.nixTools ++ packageSets.languageFormatters.general)
      # Docker tools (cross-platform)
      ++ lib.optionals (cfg.docker or false) (platformLib.platformPackages packageSets.dockerTools [ ])
      # Kubernetes tools
      ++ lib.optionals (cfg.kubernetes or false) packageSets.kubernetesTools
      # Editors
      ++ lib.optionals (cfg.vscode or false) (packageSets.editors.vscode pkgs)
      ++ lib.optionals (cfg.neovim or false) (packageSets.editors.neovim pkgs)
      ++ lib.optionals (cfg.helix or false) (packageSets.editors.helix pkgs);

    # Build shell packages (can use different versions)
    mkShellPackages =
      {
        cfg,
        pkgs,
        versions,
        # Allow version override for shells
        pythonVersion ? versions.python,
        nodeVersion ? versions.nodejs,
      }:
      with pkgs;
      lib.concatLists [
        # Rust
        (lib.optionals (cfg.rust or false) packageSets.rustToolchain)
        # Python (with version override)
        (lib.optionals (cfg.python or false) (
          let
            python = pkgs.${pythonVersion};
          in
          [
            python
            python.pkgs.pip
            python.pkgs.virtualenv
            python.pkgs.pytest
            python.pkgs.black
            python.pkgs.isort
            python.pkgs.mypy
            python.pkgs.ruff
            poetry
          ]
        ))
        # Go
        (lib.optionals (cfg.go or false) packageSets.goToolchain)
        # Node.js (with version override)
        (lib.optionals (cfg.node or false) [
          pkgs.${nodeVersion}
        ])
      ];

    # Environment variables for development
    mkDevEnvironment =
      cfg:
      lib.mkMerge [
        (lib.mkIf (cfg.rust or false) {
          RUST_BACKTRACE = "1";
          # CARGO_HOME is managed by rustup
        })
        (lib.mkIf (cfg.go or false) {
          GOPATH = "$HOME/go";
          GOBIN = "$HOME/go/bin";
        })
        (lib.mkIf (cfg.node or false) {
          NODE_OPTIONS = "--max-old-space-size=4096";
        })
        (lib.mkIf (cfg.python or false) {
          PYTHONPATH = "$HOME/.local/lib/python3.13/site-packages:$PYTHONPATH";
        })
      ];
  };
in
featureBuilders
