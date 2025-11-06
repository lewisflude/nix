{
  pkgs,
  versions,
}:
let

  getPython = pkgs: pkgs.${versions.python};
  getNodejs = pkgs: pkgs.${versions.nodejs};

  packageSets = {

    inherit getPython getNodejs;

    rustToolchain =
      # Optimized for maximum cache usage and build speed:
      # - Uses fenix.stable.withComponents with explicit component list
      #   This matches rustup's default profile + rust-src (common pattern, well-cached)
      # - All toolchain components are pre-built binaries from nix-community.cachix.org
      # - rust-analyzer-nightly from fenix overlay (pre-built, cached)
      # - cargo-* tools from nixpkgs (should be cached in nixpkgs cache)
      #
      # Component selection rationale:
      # - cargo, rustc, rustfmt, clippy: core tools (in rustup default profile)
      # - rust-src: required for rust-analyzer (not in default profile, but commonly added)
      # This combination is widely used and has excellent cache coverage
      if pkgs ? fenix && pkgs.fenix ? stable then
        with pkgs;
        [
          # Use stable toolchain with components matching rustup default + rust-src
          # This is a common pattern, so it's well-cached in nix-community.cachix.org
          (fenix.stable.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ])
          # rust-analyzer-nightly from fenix overlay (pre-built nightly, cached)
          # Falls back to nixpkgs rust-analyzer if overlay not available
          (if builtins.hasAttr "rust-analyzer-nightly" pkgs then rust-analyzer-nightly else rust-analyzer)
          # Cargo tools from nixpkgs (should be cached)
          cargo-watch
          cargo-audit
          cargo-edit
        ]
      else
        # Fallback: nixpkgs Rust packages (built from source, slower, less cache-friendly)
        with pkgs;
        [
          rustc
          cargo
          rustfmt
          clippy
          rust-analyzer
          cargo-watch
          cargo-audit
          cargo-edit
        ];

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

    nodeToolchain =
      pkgs:
      let
        nodejs = getNodejs pkgs;
      in
      with pkgs;
      [
        nodejs
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
      vscode = pkgs: [ pkgs.vscode ];
      neovim = pkgs: [ pkgs.neovim ];
      helix = pkgs: [ pkgs.helix ];
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
