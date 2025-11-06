{
  pkgs,
  versions,
}:
let
  packageSets = {
    getPython = pkgs: pkgs.${versions.python};
    getNodejs = pkgs: pkgs.${versions.nodejs};

    # Use fenix if available (via overlay), otherwise fall back to nixpkgs rust
    # Fenix is always in inputs, but overlay is conditionally applied
    rustToolchain =
      if pkgs ? fenix && pkgs.fenix ? stable then
        [
          (pkgs.fenix.stable.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ])
          (
            if builtins.hasAttr "rust-analyzer-nightly" pkgs then
              pkgs.rust-analyzer-nightly
            else
              pkgs.rust-analyzer
          )
          pkgs.cargo-watch
          pkgs.cargo-audit
          pkgs.cargo-edit
        ]
      else
        [
          pkgs.rustc
          pkgs.cargo
          pkgs.rustfmt
          pkgs.clippy
          pkgs.rust-analyzer
          pkgs.cargo-watch
          pkgs.cargo-audit
          pkgs.cargo-edit
        ];

    pythonToolchain = pkgs: [
      (pkgs.${versions.python}.withPackages (python-pkgs: [
        python-pkgs.pip
        python-pkgs.virtualenv
        python-pkgs.black
      ]))
      pkgs.ruff
      pkgs.pyright
      pkgs.poetry
    ];

    goToolchain = [
      pkgs.go
      pkgs.gopls
      pkgs.gotools
      pkgs.golangci-lint
      pkgs.delve
    ];

    nodeToolchain = pkgs: [
      pkgs.${versions.nodejs}
      pkgs.nodePackages.npm
      pkgs.nodePackages.yarn
      pkgs.nodePackages.pnpm
      pkgs.nodePackages.typescript
      pkgs.nodePackages.typescript-language-server
      pkgs.nodePackages.eslint
      pkgs.nodePackages.prettier
    ];

    luaToolchain = [
      pkgs.luajit
      pkgs.luajitPackages.luarocks
      pkgs.lua-language-server
      pkgs.stylua
      pkgs.selene
    ];

    javaToolchain = [
      pkgs.jdk
      pkgs.gradle
      pkgs.maven
    ];

    buildTools = [
      pkgs.gnumake
      pkgs.cmake
      pkgs.pkg-config
      pkgs.gcc
      pkgs.binutils
      pkgs.autoconf
      pkgs.automake
      pkgs.libtool
    ];

    gitTools = [
      pkgs.git
      pkgs.git-lfs
      pkgs.gh
      pkgs.delta
    ];

    dockerTools = [
      pkgs.docker
      pkgs.docker-compose
      pkgs.docker-credential-helpers
      pkgs.lazydocker
    ];

    kubernetesTools = [
      pkgs.kubectl
      pkgs.k9s
      pkgs.helm
      pkgs.kubernetes-helm
      pkgs.kubectx
      pkgs.kubens
    ];

    nixTools = [
      pkgs.nixfmt-rfc-style
      pkgs.nixd
      pkgs.nix-update
      pkgs.nix-prefetch-github
      pkgs.statix
    ];

    editors = {
      vscode = pkgs: [ pkgs.vscode ];
      neovim = pkgs: [ pkgs.neovim ];
      helix = pkgs: [ pkgs.helix ];
    };

    debugTools = [
      pkgs.lldb
      pkgs.gdb
    ];

    devUtilities = [
      # Note: direnv is handled via programs.direnv in home/common/apps/direnv.nix
      pkgs.nix-direnv
      # Note: jq is handled via programs.jq in home/common/apps/jq.nix
      # Note: yq is handled via programs.yq in home/common/apps/yq.nix
    ];

    languageFormatters = {
      python = [
        pkgs.ruff
        pkgs.black
      ];
      lua = [
        pkgs.stylua
        pkgs.selene
      ];
      general = [
        pkgs.biome
        pkgs.taplo
        pkgs.marksman
      ];
    };
  };
in
packageSets
