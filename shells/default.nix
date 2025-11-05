{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = (import ../lib/functions.nix {inherit lib;}).withSystem system;
  commonTools = with pkgs; [
    pre-commit
    git
  ];
  devShellsCommon = {
    qmk = import ./projects/qmk.nix {inherit pkgs lib system;};
    nextjs = import ./projects/nextjs.nix {inherit pkgs lib system;};
    react-native = import ./projects/react-native.nix {
      inherit pkgs lib system;
    };
    api-backend = import ./projects/api-backend.nix {inherit pkgs lib system;};
    development = import ./projects/development.nix {inherit pkgs lib system;};
    shell-selector = import ./utils/shell-selector.nix {inherit pkgs;};
    node = pkgs.mkShell {
      buildInputs = with pkgs;
        [(platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)] ++ commonTools;
      shellHook = ''
        echo "🚀 Node.js development environment loaded"
        echo "Node version: $(node --version)"
        echo "TypeScript version: $(tsc --version)"
      '';
    };
    python = pkgs.mkShell {
      buildInputs = with pkgs;
        [
          python312 # Python 3.13 is too new for some packages
          python312Packages.pip
          python312Packages.virtualenv
          python312Packages.pytest
          python312Packages.black
          python312Packages.isort
          python312Packages.mypy
          python312Packages.ruff
          poetry
        ]
        ++ commonTools;
      shellHook = ''
        echo "🐍 Python development environment loaded"
        echo "Python version: $(python --version)"
        export PYTHONPATH="$PWD:$PYTHONPATH"
      '';
    };
    rust = pkgs.mkShell {
      buildInputs = with pkgs;
        [
          rustc
          cargo
          rust-analyzer
          clippy
          cargo-watch
          cargo-edit
          cargo-audit
        ]
        ++ commonTools;
      shellHook = ''
        echo "🦀 Rust development environment loaded"
        echo "Rust version: $(rustc --version)"
        echo "Cargo version: $(cargo --version)"
      '';
    };
    go = pkgs.mkShell {
      buildInputs = with pkgs;
        [
          go
          gopls
          golangci-lint
          gotools
          delve
        ]
        ++ commonTools;
      shellHook = ''
        echo "🐹 Go development environment loaded"
        echo "Go version: $(go version)"
        export GOPATH="$HOME/go"
        export PATH="$GOPATH/bin:$PATH"
      '';
    };
    web = pkgs.mkShell {
      buildInputs = with pkgs;
        [
          (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
          tailwindcss-language-server
          html-tidy
          sass
        ]
        ++ commonTools;
      shellHook = ''
        echo "🌐 Web development environment loaded"
        echo "Node version: $(node --version)"
        echo "TypeScript version: $(tsc --version)"
      '';
    };
    solana = pkgs.mkShell {
      buildInputs = with pkgs;
        [
          rustc
          cargo
          (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
        ]
        ++ commonTools;
      shellHook = ''
        echo "⚡ Solana development environment loaded"
        echo "Solana version: $(solana --version)"
      '';
    };
    devops = pkgs.mkShell {
      buildInputs = with pkgs;
        [
          kubectl
          opentofu
          terragrunt
          docker-compose
          k9s
          google-cloud-sdk
          azure-cli
        ]
        ++ (lib.optionals pkgs.stdenv.isLinux [
          helm
        ]);
      shellHook = ''
        echo "🛠️  DevOps environment loaded"
        echo "kubectl version: $(kubectl version --client --short)"
        echo "OpenTofu version: $(tofu version)"
      '';
    };
  };
  devShellsLinuxOnly = platformLib.ifLinux {
    love2d = pkgs.mkShell {
      buildInputs = with pkgs;
        [
          love
          lua
          lua-language-server
          stylua
          selene
          luaPackages.luacheck
        ]
        ++ commonTools;
      shellHook = ''
        echo "🎮 Love2D game development environment loaded"
        echo "Love2D version: $(love --version 2>/dev/null || echo 'not available')"
        echo "Lua version: $(lua -v)"
        echo ""
        echo "Available tools:"
        echo "  love        - Run Love2D games"
        echo "  lua         - Lua interpreter"
        echo "  stylua      - Lua code formatter"
        echo "  selene      - Lua linter"
        echo "  luacheck    - Lua static analyzer"
        echo ""
        echo "Getting started:"
        echo "  1. Create a main.lua file"
        echo "  2. Run 'love .' to start your game"
        echo "  3. Visit https://love2d.org/wiki for documentation"
      '';
    };
  };
  # Default shell for nix-config development
  updateAllScript = import ../pkgs/pog-scripts/update-all.nix {
    inherit pkgs;
    inherit (pkgs) pog;
    config-root = toString ../.;
  };
  defaultShell = pkgs.mkShell {
    buildInputs = with pkgs; [
      # Nix tooling
      nixfmt # Nix formatter
      deadnix # Find dead Nix code
      statix # Lints and suggestions for Nix
      nixpkgs-fmt # Alternative formatter
      nix-tree # Visualize dependencies
      nix-diff # Compare derivations
      nvd # Nix version diff

      # Documentation
      mdbook # Build documentation
      graphviz # Module visualization

      # Git and utilities
      git
      pre-commit
      gh # GitHub CLI
      jq # JSON processing

      # Shell utilities
      ripgrep # Fast search
      fd # Fast find
      bat # Better cat
      eza # Better ls
      direnv # Auto-load environments
      updateAllScript
    ];

    shellHook = ''
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "🏗️  Nix Configuration Development Environment"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "📦 Available Tools:"
      echo "  • nixfmt           - Format Nix files"
      echo "  • deadnix          - Find unused code"
      echo "  • statix           - Lint Nix files"
      echo "  • nix-tree         - Visualize dependencies"
      echo "  • nvd              - Compare configurations"
      echo ""
      echo "🛠️  Custom Scripts:"
      echo "  • benchmark-rebuild.sh  - Performance monitoring"
      echo "  • diff-config.sh        - Preview changes"
      echo "  • new-module.sh         - Scaffold new modules"
      echo "  • update-flake.sh       - Update dependencies"
      echo "  • update-all              - Update all dependencies"
      echo ""
      echo "🚀 Quick Commands:"
      echo "  • nix flake check             - Run all checks"
      echo "  • nix flake update            - Update all inputs"
      echo "  • nixfmt .                    - Format all files"
      echo "  • pre-commit run --all-files  - Run linters"
      echo ""
      echo "📚 Documentation:"
      echo "  • docs/DX_GUIDE.md             - Developer experience guide"
      echo "  • docs/CONVENTIONAL_COMMENTS.md - Code review standards"
      echo "  • docs/ARCHITECTURE.md         - Architecture overview"
      echo "  • CONTRIBUTING.md              - Contributing guide"
      echo "  • templates/README.md          - Module templates"
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      # Configure git to use conventional commit template
      git config commit.template "$PWD/.gitmessage"

      # Add scripts to PATH
      export PATH="$PWD/scripts/utils:$PWD/scripts/maintenance:$PATH"

      # Set helpful aliases
      alias fmt='nixfmt .'
      alias lint='statix check .'
      alias check='nix flake check'
      alias update='nix flake update'
      alias build-darwin='nix build .#darwinConfigurations.Lewiss-MacBook-Pro.system'
      alias build-nixos='nix build .#nixosConfigurations.jupiter.config.system.build.toplevel'
    '';
  };
in {
  devShells = devShellsCommon // devShellsLinuxOnly // {default = defaultShell;};
}
