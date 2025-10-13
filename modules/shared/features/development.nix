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
        # Note: Rust toolchain is managed by rustup (installed in packages.nix)
        # ++ optionals cfg.rust [
        #   rustc
        #   cargo
        #   rustfmt
        #   clippy
        #   rust-analyzer
        # ]
        ++ optionals cfg.python [
          python313
          python313Packages.pip
          python313Packages.virtualenv
          python313Packages.uv
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
          nodejs_24 # Latest LTS version with full binary cache support
          # Note: npm, npx, and corepack (for pnpm/yarn) are included
          # Install typescript and language servers via npm/npx as needed
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
        # CARGO_HOME is managed by rustup
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
