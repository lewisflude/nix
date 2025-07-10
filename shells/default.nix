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
    # Node.js/TypeScript development
    node = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs_24
        typescript
        nodePackages_latest.pnpm
        nodePackages_latest.npm
        nodePackages_latest.yarn
        nodePackages_latest.eslint
        nodePackages_latest.prettier
        nodePackages_latest.typescript-language-server
        nodePackages_latest.vscode-langservers-extracted
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
        typescript
        nodePackages_latest.pnpm
        nodePackages_latest.eslint
        nodePackages_latest.prettier
        nodePackages_latest.typescript-language-server
        nodePackages_latest.vscode-langservers-extracted
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
        nodePackages_latest.pnpm
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
