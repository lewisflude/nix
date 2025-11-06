{
  pkgs,
  versions,
}:
let

  getPython = pkgs: pkgs.${versions.python};
  getNodejs = pkgs: pkgs.${versions.nodejs};

  packageSets = {

    inherit getPython getNodejs;

    rustToolchain = with pkgs; [
      # Use rust-overlay's pre-built binary toolchain (much faster than building from source)
      # rust-bin.stable.latest.default provides: rustc, cargo, rustfmt, clippy, rust-std, rust-docs
      # This matches rustup's default profile and uses pre-built binaries (no compilation needed)
      (rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" ]; # Include rust-src for rust-analyzer
      })
      # rust-analyzer and cargo tools still come from nixpkgs (usually cached in binary caches)
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
