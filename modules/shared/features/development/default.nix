# Development feature module (cross-platform)
# Controlled by host.features.development.*
# Provides comprehensive development environment with languages, tools, and editors
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
with lib; let
  cfg = config.host.features.development;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  isLinux = platformLib.isLinux;
  isDarwin = platformLib.isDarwin;
in {
  config = mkIf cfg.enable {
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
      (mkIf cfg.python {
        PYTHONPATH = "$HOME/.local/lib/python3.13/site-packages:$PYTHONPATH";
      })
    ];

    # System-level packages (NixOS only)
    environment.systemPackages = mkIf isLinux (
      with pkgs;
        [
          # Build tools (always included when buildTools is enabled)
        ]
        ++ optionals cfg.buildTools [
          gnumake
          cmake
          pkg-config
          gcc
          binutils
          autoconf
          automake
          libtool
          # Development headers
          glibc.dev
        ]
        # Git tools
        ++ optionals cfg.git [
          git
          git-lfs
          gh # GitHub CLI
          delta # Git diff viewer
        ]
        # Rust toolchain
        ++ optionals cfg.rust [
          rustc
          cargo
          rustfmt
          clippy
          rust-analyzer
          cargo-watch
          cargo-audit
          cargo-edit
        ]
        # Python toolchain
        ++ optionals cfg.python [
          python313
          python313Packages.pip
          python313Packages.virtualenv
          python313Packages.uv
          ruff # Fast Python linter
          pyright # Python language server
          black # Python formatter
          poetry # Python dependency management
        ]
        # Go toolchain
        ++ optionals cfg.go [
          go
          gopls # Go language server
          gotools
          golangci-lint
          delve # Go debugger
        ]
        # Node.js/TypeScript toolchain
        ++ optionals cfg.node [
          nodejs_24
          nodejs_24.pkgs.npm
          nodejs_24.pkgs.yarn
          nodejs_24.pkgs.pnpm
          nodejs_24.pkgs.typescript
          nodejs_24.pkgs.typescript-language-server
          nodejs_24.pkgs.eslint
          nodejs_24.pkgs.prettier
        ]
        # Lua toolchain
        ++ optionals cfg.lua [
          luajit
          luajitPackages.luarocks
          lua-language-server
          stylua # Lua formatter
          selene # Lua linter
        ]
        # Java toolchain
        ++ optionals cfg.java [
          jdk
          gradle
          maven
        ]
        # Nix development tools
        ++ optionals cfg.nix [
          nixfmt-rfc-style
          nixd # Nix language server
          nix-update # Update package versions
          nix-prefetch-github
          statix # Nix linter
        ]
        # Docker tools
        ++ optionals cfg.docker [
          docker-client
          docker-compose
          docker-credential-helpers
          lazydocker # Docker TUI
        ]
        # Kubernetes tools
        ++ optionals cfg.kubernetes [
          kubectl
          k9s # Kubernetes TUI
          helm
          kubernetes-helm
          kubectx
          kubens
        ]
        # Editors (system-level)
        ++ optionals cfg.vscode [vscode]
        ++ optionals cfg.neovim [neovim]
        ++ optionals cfg.helix [pkgs.helix]
    );

    # NixOS-specific services
    virtualisation.docker = mkIf (isLinux && cfg.docker) {
      enable = true;
      daemon.settings = {
        data-root = "/var/lib/docker";
      };
    };

    # User groups for Docker
    users.users.${config.host.username}.extraGroups = optional (isLinux && cfg.docker) "docker";

    # Assertions
    assertions = [
      {
        assertion = cfg.rust -> (cfg.git or false);
        message = "Rust development requires Git to be enabled";
      }
      {
        assertion = (cfg.kubernetes or false) -> (cfg.docker or false);
        message = "Kubernetes development tools require Docker to be enabled";
      }
    ];
  };
}
