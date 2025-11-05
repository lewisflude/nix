# Package sets for development toolchains
# Single source of truth for all development packages
# This file is pure and has no dependencies on inputs or modules
{
  pkgs,
  versions,
}:
let
  # Version-aware package getters (defined at top level for use in other functions)
  getPython = pkgs: pkgs.${versions.python};
  getNodejs = pkgs: pkgs.${versions.nodejs};

  packageSets = {
    # Version-aware package getters
    inherit getPython getNodejs;

    # Rust toolchain (complete set)
    rustToolchain = with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      cargo-watch
      cargo-audit
      cargo-edit
    ];

    # Python toolchain (complete set)
    # Follows wiki pattern: https://nixos.wiki/wiki/Python
    # Uses python3.withPackages as recommended in the wiki
    pythonToolchain =
      pkgs:
      let
        python = getPython pkgs;
      in
      with pkgs;
      [
        (python.withPackages (
          python-pkgs: with python-pkgs; [
            pip
            virtualenv
            black
          ]
        ))
        # Standalone tools (not Python packages)
        ruff
        pyright
        poetry
      ];

    # Go toolchain
    goToolchain = with pkgs; [
      go
      gopls
      gotools
      golangci-lint
      delve
    ];

    # Node.js/TypeScript toolchain
    nodeToolchain =
      pkgs:
      let
        nodejs = getNodejs pkgs;
      in
      with pkgs;
      [
        nodejs
        nodejs.pkgs.npm
        nodejs.pkgs.yarn
        nodejs.pkgs.pnpm
        nodejs.pkgs.typescript
        nodejs.pkgs.typescript-language-server
        nodejs.pkgs.eslint
        nodejs.pkgs.prettier
      ];

    # Lua toolchain
    luaToolchain = with pkgs; [
      luajit
      luajitPackages.luarocks
      lua-language-server
      stylua
      selene
    ];

    # Java toolchain
    javaToolchain = with pkgs; [
      jdk
      gradle
      maven
    ];

    # Build tools
    buildTools = with pkgs; [
      gnumake
      cmake
      pkg-config
      gcc
      binutils
      autoconf
      automake
      libtool
    ];

    # Git tools
    gitTools = with pkgs; [
      git
      git-lfs
      gh
      delta
    ];

    # Docker tools
    dockerTools = with pkgs; [
      docker-client
      docker-compose
      docker-credential-helpers
      lazydocker
    ];

    # Kubernetes tools
    kubernetesTools = with pkgs; [
      kubectl
      k9s
      helm
      kubernetes-helm
      kubectx
      kubens
    ];

    # Nix development tools
    nixTools = with pkgs; [
      nixfmt-rfc-style
      nixd
      nix-update
      nix-prefetch-github
      statix
    ];

    # Editors
    editors = {
      vscode = pkgs: [ pkgs.vscode ];
      neovim = pkgs: [ pkgs.neovim ];
      helix = pkgs: [ pkgs.helix ];
    };

    # Debugging tools
    debugTools = with pkgs; [
      lldb
      gdb
    ];

    # General development utilities
    devUtilities = with pkgs; [
      direnv
      nix-direnv
      jq
      yq
    ];

    # Language-specific formatters/linters (not in toolchains)
    languageFormatters = with pkgs; {
      python = [
        ruff
        black
      ];
      lua = [
        stylua
        selene
      ];
      general = [
        biome
        taplo
        marksman
      ];
    };
  };
in
packageSets
