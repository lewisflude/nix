{
  pkgs,
  lib,
  system,
  ...
}:

{
  # Development shells for different project types
  devShells = {
    # Project-specific shells
    nextjs = import ./projects/nextjs.nix { inherit pkgs; };
    react-native = import ./projects/react-native.nix { inherit pkgs lib system; };
    api-backend = import ./projects/api-backend.nix { inherit pkgs; };

    # Utility shells
    shell-selector = import ./utils/shell-selector.nix { inherit pkgs; };

    # Love2D game development
    love2d = pkgs.mkShell {
      buildInputs = with pkgs; [
        love # Love2D game engine
        lua # Lua interpreter
        lua-language-server # Lua LSP
        stylua # Lua formatter
        selene # Lua linter
        luaPackages.luacheck # Lua static analyzer
      ];

      shellHook = ''
        echo "🎮 Love2D game development environment loaded"
        echo "Love2D version: $(love --version 2>/dev/null || echo 'love command not found')"
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

    # Node.js/TypeScript development
    node = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs_24
      ];

      shellHook = ''
        echo "🚀 Node.js development environment loaded"
        echo "Node version: $(node --version)"
        echo "TypeScript version: $(tsc --version)"
      '';
    };

    # Python development
    python = pkgs.mkShell {
      buildInputs = with pkgs; [
        python313
        python313Packages.pip
        python313Packages.virtualenv
        python313Packages.pytest
        python313Packages.black
        python313Packages.isort
        python313Packages.mypy
        python313Packages.ruff
        poetry
      ];

      shellHook = ''
        echo "🐍 Python development environment loaded"
        echo "Python version: $(python --version)"
        export PYTHONPATH="$PWD:$PYTHONPATH"
      '';
    };

    # Rust development
    rust = pkgs.mkShell {
      buildInputs = with pkgs; [
        rustc
        cargo
        rust-analyzer
        clippy
        cargo-watch
        cargo-edit
        cargo-audit
      ];

      shellHook = ''
        echo "🦀 Rust development environment loaded"
        echo "Rust version: $(rustc --version)"
        echo "Cargo version: $(cargo --version)"
      '';
    };

    # Go development
    go = pkgs.mkShell {
      buildInputs = with pkgs; [
        go
        gopls
        golangci-lint
        gotools
        delve
      ];

      shellHook = ''
        echo "🐹 Go development environment loaded"
        echo "Go version: $(go version)"
        export GOPATH="$HOME/go"
        export PATH="$GOPATH/bin:$PATH"
      '';
    };

    # Web development (full-stack)
    web = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs_24
        tailwindcss-language-server
        html-tidy
        sass
      ];

      shellHook = ''
        echo "🌐 Web development environment loaded"
        echo "Node version: $(node --version)"
        echo "TypeScript version: $(tsc --version)"
      '';
    };

    # Blockchain/Solana development
    solana = pkgs.mkShell {
      buildInputs = with pkgs; [
        solana-cli
        rustc
        cargo
        nodejs_24
      ];

      shellHook = ''
        echo "⚡ Solana development environment loaded"
        echo "Solana version: $(solana --version)"
      '';
    };

    # DevOps/Infrastructure
    devops = pkgs.mkShell {
      buildInputs = with pkgs; [
        kubectl
        helm
        opentofu
        terragrunt
        docker-compose
        k9s
        awscli2
        google-cloud-sdk
        azure-cli
      ];

      shellHook = ''
        echo "🛠️  DevOps environment loaded"
        echo "kubectl version: $(kubectl version --client --short)"
        echo "OpenTofu version: $(tofu version)"
      '';
    };
  };
}
