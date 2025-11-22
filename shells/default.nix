{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../lib/functions.nix { inherit lib; }).withSystem system;
  packageSets = import ../lib/package-sets.nix {
    inherit pkgs;
  };
  featureBuilders = import ../lib/feature-builders.nix {
    inherit lib packageSets;
  };
  commonTools = [
    pkgs.pre-commit
    pkgs.git
  ];
  devShellsCommon = {
    # Project-specific shells
    qmk = import ./projects/qmk.nix { inherit pkgs lib system; };
    nextjs = import ./projects/nextjs.nix { inherit pkgs lib system; };
    react-native = import ./projects/react-native.nix {
      inherit pkgs lib system;
    };
    api-backend = import ./projects/api-backend.nix { inherit pkgs lib system; };
    development = import ./projects/development.nix { inherit pkgs lib system; };
    shell-selector = import ./utils/shell-selector.nix { inherit pkgs; };

    # Language shells
    # Note: rust, python, node are now in devShells (not system-wide) to reduce system size
    # Use: nix develop .#rust or direnv with .envrc

    rust = import ./projects/rust.nix { inherit pkgs lib system; };
    python = import ./projects/python.nix { inherit pkgs lib system; };
    node = import ./projects/node.nix { inherit pkgs lib system; };

    # Language shells for non-default languages
    go = pkgs.mkShell {
      buildInputs =
        featureBuilders.mkShellPackages {
          cfg = {
            go = true;
          };
          inherit pkgs;
        }
        ++ commonTools;
      shellHook = ''
        echo "🐹 Go development environment loaded"
        echo "Go version: $(go version)"
        export GOPATH="$HOME/go"
        export PATH="$GOPATH/bin:$PATH"
      '';
    };

    # Web-specific tools (extends system node/typescript)
    web = pkgs.mkShell {
      buildInputs = [
        # System provides: node, typescript, pnpm
        # Add web-specific tools only
        pkgs.tailwindcss-language-server
        pkgs.html-tidy
        pkgs.sass
      ]
      ++ commonTools;
      shellHook = ''
        echo "🌐 Web development environment loaded (using system Node.js)"
        echo "Node version: $(node --version)"
        echo "Additional tools: tailwindcss-ls, html-tidy, sass"
      '';
    };

    # DevOps tools (specialized environment)
    devops = pkgs.mkShell {
      buildInputs = [
        pkgs.kubectl
        pkgs.opentofu
        pkgs.terragrunt
        pkgs.docker-compose
        pkgs.k9s
        pkgs.google-cloud-sdk
        pkgs.azure-cli
      ]
      ++ (lib.optionals pkgs.stdenv.isLinux [
        pkgs.helm
      ]);
      shellHook = ''
        echo "🛠️  DevOps environment loaded"
        echo "kubectl version: $(kubectl version --client --short)"
        echo "OpenTofu version: $(tofu version)"
      '';
    };
  };
  devShellsLinuxOnly = lib.optionalAttrs platformLib.isLinux {
    love2d = pkgs.mkShell {
      buildInputs = [
        pkgs.love
        pkgs.lua
        pkgs.lua-language-server
        pkgs.stylua
        pkgs.selene
        pkgs.luaPackages.luacheck
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

  updateAllScript = import ../pkgs/pog-scripts/update-all.nix {
    inherit pkgs;
    inherit (pkgs) pog;
    config-root = toString ../.;
  };
  defaultShell = pkgs.mkShell {
    buildInputs = [

      pkgs.nixfmt-rfc-style
      pkgs.deadnix
      pkgs.statix
      pkgs.treefmt
      pkgs.nix-tree
      pkgs.nix-diff
      pkgs.nvd

      pkgs.mdbook
      pkgs.graphviz

      pkgs.git
      pkgs.pre-commit
      pkgs.gh
      pkgs.jq

      pkgs.ripgrep
      pkgs.fd
      pkgs.bat
      pkgs.eza
      pkgs.direnv
      updateAllScript
    ];

    shellHook = ''
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "🏗️  Nix Configuration Development Environment"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "📦 Available Tools:"
      echo "  • nixfmt-rfc-style - Official Nix formatter (RFC 166)"
      echo "  • treefmt          - Unified formatter (Nix, YAML, Markdown, Shell)"
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
      echo "  • nix fmt                     - Format all Nix files (flake formatter)"
      echo "  • treefmt                     - Format all files (Nix, YAML, Markdown, Shell)"
      echo "  • format.sh treefmt           - Format using helper script"
      echo "  • fmt                         - Alias for nix fmt"
      echo "  • pre-commit run --all-files  - Run linters"
      echo ""
      echo "📚 Documentation:"
      echo "  • docs/DX_GUIDE.md             - Developer experience guide"
      echo "  • docs/CONVENTIONAL_COMMENTS.md - Code review standards"
      echo "  • docs/reference/architecture.md - Architecture overview"
      echo "  • CONTRIBUTING.md              - Contributing guide"
      echo "  • templates/README.md          - Module templates"
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


      git config commit.template "$PWD/.gitmessage"

      alias fmt='nix fmt'
      alias fmt-nix='nixfmt-rfc-style'
      alias fmt-all='treefmt'
      alias lint='statix check .'
      alias check='nix flake check'
      alias update='nix flake update'
      alias build-darwin='nix build .
      alias build-nixos='nix build .
    '';
  };
in
{
  devShells = devShellsCommon // devShellsLinuxOnly // { default = defaultShell; };
}
