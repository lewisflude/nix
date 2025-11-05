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
with lib; let
  cfg = host.features.development;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  isLinux = platformLib.isLinux;
  isDarwin = platformLib.isDarwin;
in {
  imports = [
    ./version-control.nix
    ./language-tools.nix
  ];

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        # General development tools (always included)
        direnv
        nix-direnv
        jq
        yq
        # Debugging tools
        lldb
        gdb
      ]
      # Build tools
      ++ optionals (cfg.buildTools or false) [
        gnumake
        cmake
        pkg-config
        autoconf
        automake
        libtool
      ]
      # Git tools (if not already in core-tooling)
      ++ optionals (cfg.git or false) [
        delta # Git diff viewer
        git-lfs
        # gh, git, curl, wget are in core-tooling.nix
      ]
      # Rust toolchain (user-level)
      ++ optionals (cfg.rust or false) [
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
      ++ optionals (cfg.python or false) [
        python313
        python313Packages.pip
        python313Packages.virtualenv
        python313Packages.uv
        ruff
        pyright
        black
        poetry
      ]
      # Go toolchain
      ++ optionals (cfg.go or false) [
        go
        gopls
        gotools
        golangci-lint
        delve
      ]
      # Node.js/TypeScript toolchain
      ++ optionals (cfg.node or false) [
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
      ++ optionals (cfg.lua or false) [
        luajit
        luajitPackages.luarocks
        lua-language-server
        stylua
        selene
      ]
      # Java toolchain
      ++ optionals (cfg.java or false) [
        jdk
        gradle
        maven
      ]
      # Nix development tools
      ++ optionals (cfg.nix or false) [
        nixfmt-rfc-style
        nixd
        nix-update
        nix-prefetch-github
        statix
        biome
        taplo
        marksman
      ]
      # Docker tools (cross-platform)
      ++ optionals (cfg.docker or false) (
        platformLib.platformPackages
        [
          docker-client
          docker-compose
          docker-credential-helpers
          lazydocker
        ]
        []
      )
      # Kubernetes tools (cross-platform)
      ++ optionals (cfg.kubernetes or false) [
        kubectl
        k9s
        helm
        kubectx
        kubens
      ]
      # Editors
      ++ optionals (cfg.vscode or false) [vscode]
      ++ optionals (cfg.neovim or false) [neovim]
      ++ optionals (cfg.helix or false) [pkgs.helix];

    # Program configurations
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Git configuration (if git is enabled)
    programs.git = mkIf (cfg.git or false) {
      enable = true;
      lfs.enable = true;
    };

    # Editor configurations
    programs.neovim = mkIf (cfg.neovim or false) {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };

    programs.helix = mkIf (cfg.helix or false) {
      enable = true;
    };
  };
}
