{ pkgs, lib, ... }:

{
  # Development shells for different project types
  devShells = {
    # Project-specific shells
    nextjs = import ./projects/nextjs.nix { inherit pkgs; };
    react-native = import ./projects/react-native.nix { inherit pkgs lib; };
    api-backend = import ./projects/api-backend.nix { inherit pkgs; };
    
    # Utility shells
    shell-selector = import ./utils/shell-selector.nix { inherit pkgs; };
    # Node.js/TypeScript development
    node = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs_22
        typescript
        nodePackages.pnpm
        nodePackages.npm
        nodePackages.yarn
        nodePackages.eslint
        nodePackages.prettier
        nodePackages.typescript-language-server
        nodePackages.vscode-langservers-extracted
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
        python312
        python312Packages.pip
        python312Packages.virtualenv
        python312Packages.pytest
        python312Packages.black
        python312Packages.isort
        python312Packages.mypy
        python312Packages.ruff
        python312Packages.poetry
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
        rustfmt
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
        nodejs_22
        typescript
        nodePackages.pnpm
        nodePackages.eslint
        nodePackages.prettier
        nodePackages.typescript-language-server
        nodePackages.vscode-langservers-extracted
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
        nodejs_22
        nodePackages.pnpm
        anchor-cli
      ];
      
      shellHook = ''
        echo "⚡ Solana development environment loaded"
        echo "Solana version: $(solana --version)"
        echo "Anchor version: $(anchor --version)"
      '';
    };

    # DevOps/Infrastructure
    devops = pkgs.mkShell {
      buildInputs = with pkgs; [
        kubectl
        helm
        terraform
        terragrunt
        docker
        docker-compose
        k9s
        aws-cli
        gcloud
        azure-cli
      ];
      
      shellHook = ''
        echo "🛠️  DevOps environment loaded"
        echo "kubectl version: $(kubectl version --client --short)"
        echo "terraform version: $(terraform version)"
      '';
    };
  };
}