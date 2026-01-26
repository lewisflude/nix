{
  pkgs,
}:
let
  packageSets = {
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
      (pkgs.python3.withPackages (python-pkgs: [
        python-pkgs.pip
        python-pkgs.virtualenv
        python-pkgs.black
      ]))
      pkgs.ruff
      pkgs.pyright
    ];

    goToolchain = [
      pkgs.go
      pkgs.gopls
      pkgs.gotools
      pkgs.golangci-lint
      pkgs.delve
    ];

    nodeToolchain = pkgs: [
      pkgs.nodejs
      pkgs.nodePackages.pnpm
      pkgs.nodePackages.typescript
    ];

    luaToolchain = [
      pkgs.luajit
    ];

    buildTools = [
      pkgs.gnumake
      pkgs.cmake
      pkgs.pkg-config
      pkgs.gcc
      pkgs.binutils
    ];

    dockerTools = [
      pkgs.docker-compose
      pkgs.docker-credential-helpers
    ];

    kubernetesTools = [
      pkgs.kubectl
      pkgs.k9s
      pkgs.kubernetes-helm
      pkgs.kubectx
      pkgs.kubens
    ];

    nixTools = [
      pkgs.nixfmt
      pkgs.nixd
      pkgs.nix-update
      pkgs.nix-prefetch-github
      pkgs.statix
    ];

    editors = {
      vscode = [ pkgs.vscode ];
      neovim = [ pkgs.neovim ];
      helix = [ pkgs.helix ];
    };

    # Debug tools are conditionally included via cfg.debugTools option
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
      general = [
        pkgs.biome
        pkgs.taplo
      ];
    };
  };
in
packageSets
