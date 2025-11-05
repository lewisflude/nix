# Package sets for development toolchains
# Single source of truth for all development packages
# This file is pure and has no dependencies on inputs or modules
{
  pkgs,
  versions,
}:
rec {
  # Version-aware package getters
  getPython = pkgs: pkgs.${versions.python};
  getNodejs = pkgs: pkgs.${versions.nodejs};

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
  pythonToolchain =
    pkgs:
    let
      python = getPython pkgs;
    in
    with pkgs;
    [
      python
      python.pkgs.pip
      python.pkgs.virtualenv
      python.pkgs.uv
      ruff
      pyright
      black
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
}
