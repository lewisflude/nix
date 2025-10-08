{pkgs, ...}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    fzf
    bat
    fd
  ];

  shellHook = ''
    # Interactive shell selector
    select_dev_shell() {
      echo "🚀 Available development environments:"
      echo ""

      local shells=(
        "nextjs:⚡ Next.js React framework"
        "react-native:📱 React Native mobile apps"
        "api-backend:🔧 API/Backend services"
        "node:📦 General Node.js/TypeScript"
        "python:🐍 Python development"
        "rust:🦀 Rust development"
        "go:🐹 Go development"
        "web:🌐 Full-stack web development"
        "solana:⚡ Blockchain/Solana development"
        "devops:🛠️  DevOps/Infrastructure"
      )

      local choice=$(printf '%s\n' "''${shells[@]}" | fzf --ansi --preview 'echo {}' --preview-window=right:50% --prompt="Select environment: ")

      if [[ -n "$choice" ]]; then
        local shell_name=$(echo "$choice" | cut -d':' -f1)
        echo "Loading $shell_name environment..."
        nix develop ~/.config/nix#$shell_name
      fi
    }

    # Quick project setup
    setup_project() {
      echo "🎯 Project Setup Wizard"
      echo ""
      echo "1. Next.js (React)"
      echo "2. React Native (Mobile)"
      echo "3. API Backend (Node.js)"
      echo "4. Python Project"
      echo "5. Rust Project"
      echo ""
      read -p "Select project type (1-5): " choice

      case $choice in
        1)
          echo "Setting up Next.js project..."
          cp ~/.config/nix/shells/envrc-templates/nextjs .envrc
          echo "✅ Created .envrc for Next.js"
          ;;
        2)
          echo "Setting up React Native project..."
          cp ~/.config/nix/shells/envrc-templates/mobile .envrc
          echo "✅ Created .envrc for React Native"
          ;;
        3)
          echo "Setting up API Backend project..."
          cp ~/.config/nix/shells/envrc-templates/api .envrc
          echo "✅ Created .envrc for API Backend"
          ;;
        4)
          echo "Setting up Python project..."
          cp ~/.config/nix/shells/envrc-templates/python .envrc
          echo "✅ Created .envrc for Python"
          ;;
        5)
          echo "Setting up Rust project..."
          cp ~/.config/nix/shells/envrc-templates/rust .envrc
          echo "✅ Created .envrc for Rust"
          ;;
        *)
          echo "Invalid selection"
          ;;
      esac

      if [[ -f ".envrc" ]]; then
        echo ""
        echo "🎉 Project setup complete!"
        echo "Run 'direnv allow' to activate the environment"
      fi
    }

    # Export functions
    export -f select_dev_shell
    export -f setup_project

    echo "🛠️  Development utilities loaded"
    echo "Commands available:"
    echo "  select_dev_shell - Interactive shell selector"
    echo "  setup_project    - Quick project setup wizard"
  '';
}
