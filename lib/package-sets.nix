{
  pkgs,
  versions,
}: let
  packageSets = {
    getPython = pkgs: pkgs.${versions.python};
    getNodejs = pkgs: pkgs.${versions.nodejs};

    rustToolchain =
      if pkgs ? fenix && pkgs.fenix ? stable
      then
        with pkgs; [
          (fenix.stable.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ])
          (
            if builtins.hasAttr "rust-analyzer-nightly" pkgs
            then rust-analyzer-nightly
            else rust-analyzer
          )
          cargo-watch
          cargo-audit
          cargo-edit
        ]
      else
        with pkgs; [
          rustc
          cargo
          rustfmt
          clippy
          rust-analyzer
          cargo-watch
          cargo-audit
          cargo-edit
        ];

    pythonToolchain = pkgs:
      with pkgs; [
        ((pkgs.${versions.python}).withPackages (
          python-pkgs:
            with python-pkgs; [
              pip
              virtualenv
              black
            ]
        ))
        ruff
        pyright
        poetry
      ];

    goToolchain = with pkgs; [
      go
      gopls
      gotools
      golangci-lint
      delve
    ];

    nodeToolchain = pkgs:
      with pkgs; [
        pkgs.${versions.nodejs}
        nodePackages.npm
        nodePackages.yarn
        nodePackages.pnpm
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.eslint
        nodePackages.prettier
      ];

    luaToolchain = with pkgs; [
      luajit
      luajitPackages.luarocks
      lua-language-server
      stylua
      selene
    ];

    javaToolchain = with pkgs; [
      jdk
      gradle
      maven
    ];

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

    gitTools = with pkgs; [
      git
      git-lfs
      gh
      delta
    ];

    dockerTools = with pkgs; [
      docker-client
      docker-compose
      docker-credential-helpers
      lazydocker
    ];

    kubernetesTools = with pkgs; [
      kubectl
      k9s
      helm
      kubernetes-helm
      kubectx
      kubens
    ];

    nixTools = with pkgs; [
      nixfmt-rfc-style
      nixd
      nix-update
      nix-prefetch-github
      statix
    ];

    editors = {
      vscode = pkgs: [pkgs.vscode];
      neovim = pkgs: [pkgs.neovim];
      helix = pkgs: [pkgs.helix];
    };

    debugTools = with pkgs; [
      lldb
      gdb
    ];

    devUtilities = with pkgs; [
      direnv
      nix-direnv
      jq
      yq
    ];

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
