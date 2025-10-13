# Development feature module (cross-platform)
# Controlled by host.features.development.*
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.development;
in {
  config = mkIf cfg.enable {
    # Install development packages based on enabled languages
    home-manager.users.${config.host.username} = {
      home.packages = with pkgs;
        [
          # Core development tools
          git
          gh
          curl
          wget
          jq
          yq
        ]
        # Language-specific tools
        ++ optionals cfg.rust [
          rustc
          cargo
          rustfmt
          clippy
          rust-analyzer
        ]
        ++ optionals cfg.python [
          python3
          python3Packages.pip
          python3Packages.virtualenv
          ruff
          pyright
        ]
        ++ optionals cfg.go [
          go
          gopls
          gotools
          go-tools
        ]
        ++ optionals cfg.node [
          nodejs
          nodePackages.npm
          nodePackages.pnpm
          nodePackages.yarn
          nodePackages.typescript
          nodePackages.typescript-language-server
        ]
        ++ optionals cfg.lua [
          lua
          luajit
          luajitPackages.luarocks
          lua-language-server
        ];
    };

    # Environment variables for development
    environment.variables = mkMerge [
      (mkIf cfg.rust {
        RUST_BACKTRACE = "1";
        CARGO_HOME = "$HOME/.cargo";
      })
      (mkIf cfg.go {
        GOPATH = "$HOME/go";
        GOBIN = "$HOME/go/bin";
      })
      (mkIf cfg.node {
        NODE_OPTIONS = "--max-old-space-size=4096";
      })
    ];
  };
}
