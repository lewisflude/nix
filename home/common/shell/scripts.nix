{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    (writeShellScriptBin "system-update" ''
      #!/bin/sh
      # system-update: Cross-platform NixOS/Darwin system update script
      # Usage: system-update [options]
      #   --full      Do a complete update (flake update + GC)
      #   --inputs    Update flake inputs
      #   --gc        Run garbage collection
      #   --help      Show this help

      set -e # Exit on error

      FLAKE_PATH="${config.home.homeDirectory}/.config/nix"
      UPDATE_INPUTS=0
      RUN_GC=0
      BUILD_ONLY=0

      # Detect platform and set appropriate commands
      if [[ "$OSTYPE" == "darwin"* ]]; then
        HOST_NAME="Lewiss-MacBook-Pro"
        SYSTEM_BUILD_CMD="darwin-rebuild build --flake"
        SYSTEM_SWITCH_CMD="darwin-rebuild switch --flake"
        HOME_BUILD_CMD="home-manager build --flake"
        HOME_SWITCH_CMD="home-manager switch --flake"
        FLAKE_CONFIG="$FLAKE_PATH#$HOST_NAME"
        HOME_CONFIG="$FLAKE_PATH#lewis@$HOST_NAME"
      else
        HOST_NAME="jupiter"
        SYSTEM_BUILD_CMD="sudo nixos-rebuild build --flake"
        SYSTEM_SWITCH_CMD="sudo nixos-rebuild switch --flake"
        HOME_BUILD_CMD="home-manager build --flake"
        HOME_SWITCH_CMD="home-manager switch --flake"
        FLAKE_CONFIG="$FLAKE_PATH#$HOST_NAME"
        HOME_CONFIG="$FLAKE_PATH#lewis@$HOST_NAME"
      fi

      # Parse arguments
      if [ $# -eq 0 ]; then
        # Default behavior - no flake update, no GC
        :
      else
        for arg in "$@"; do
          case $arg in
            --full)
              UPDATE_INPUTS=1
              RUN_GC=1
              ;;
            --inputs)
              UPDATE_INPUTS=1
              ;;
            --gc)
              RUN_GC=1
              ;;
            --build-only)
              BUILD_ONLY=1
              ;;
            --help)
              echo "Usage: system-update [options]"
              echo "  --full       Do a complete update (flake update + GC)"
              echo "  --inputs     Update flake inputs"
              echo "  --gc         Run garbage collection"
              echo "  --build-only Just build but don't activate"
              echo "  --help       Show this help"
              exit 0
              ;;
          esac
        done
      fi

      # Update flake inputs only when requested
      if [ $UPDATE_INPUTS -eq 1 ]; then
        echo "🔄 Updating flake inputs..."
        nix flake update --flake "$FLAKE_PATH"
      fi

      # Switch or build based on argument
      if [ $BUILD_ONLY -eq 1 ]; then
        echo "⚙️ Building system configuration (without activating)..."
        $SYSTEM_BUILD_CMD $FLAKE_CONFIG

        echo "🏠 Building home-manager configuration (without activating)..."
        $HOME_BUILD_CMD $HOME_CONFIG
      else
        echo "⚙️ Building and activating system configuration..."
        $SYSTEM_SWITCH_CMD $FLAKE_CONFIG

        echo "🏠 Updating home-manager configuration..."
        $HOME_SWITCH_CMD $HOME_CONFIG
      fi

      # Run garbage collection only when requested
      if [ $RUN_GC -eq 1 ]; then
        echo "🧹 Running garbage collection..."
        nix-collect-garbage -d
      fi

      echo "✨ System update complete!"

      # Print current system and home-manager generations
      if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Current darwin generation:"
        darwin-rebuild --list-generations | tail -n 1
      else
        echo "Current system generation:"
        sudo nix-env -p /nix/var/nix/profiles/system --list-generations | tail -n 1
      fi

      echo "Current home-manager generation:"
      home-manager generations | head -n 1
    '')
    (writeShellScriptBin "link-pipewire-nodes" ''
      #!/usr/bin/env bash

      # ports obtained from `pw-link -io`

      pw-link "Main-Output-Proxy:monitor_FL" "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0"
      pw-link "Main-Output-Proxy:monitor_FR" "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1"

      pw-link "alsa_input.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-input-0:capture_AUX0" "Microphone-Proxy:input_MONO"

    '')

    # Unreal Engine setup and development scripts
    (writeShellScriptBin "ue5-setup" ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "🎮 Unreal Engine 5 Setup Guide"
      echo "═══════════════════════════════"
      echo ""
      echo "📋 Prerequisites Check:"

      # Check Epic Games Launcher
      if [ -d "/Applications/Epic Games Launcher.app" ]; then
        echo "  ✅ Epic Games Launcher is installed"
      else
        echo "  ❌ Epic Games Launcher not found"
        echo "     Run: brew install --cask epic-games"
      fi

      # Check Xcode
      if command -v xcodebuild &> /dev/null; then
        XCODE_VERSION=$(xcodebuild -version | grep "Xcode" | cut -d " " -f2)
        echo "  ✅ Xcode $XCODE_VERSION is installed"
      else
        echo "  ❌ Xcode not found"
        echo "     Install from Mac App Store"
      fi

      # Check development tools
      if command -v clangd &> /dev/null; then
        echo "  ✅ C++ development tools are ready"
      else
        echo "  ❌ C++ tools not found"
        echo "     Run: darwin-rebuild switch"
      fi

      echo ""
      echo "🔄 Installation Steps:"
      echo "  1. Open Epic Games Launcher"
      echo "  2. Create/login to Epic Games account"
      echo "  3. Navigate to Unreal Engine tab"
      echo "  4. Install Unreal Engine 5.x"
      echo ""
      echo "💡 Development Setup:"
      echo "  - Recommended IDE: JetBrains Rider"
      echo "  - Alternative: VS Code with C/C++ extension"
      echo "  - For large projects: Enable Git LFS (run git-game-setup)"
      echo ""
      echo "🚀 Ready to create your first UE5 project!"
    '')

    (writeShellScriptBin "git-game-setup" ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "🎮 Setting up Git for game development..."

      # Check if we're in a git repository
      if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a Git repository. Run 'git init' first."
        exit 1
      fi

      # Initialize Git LFS
      echo "🔧 Initializing Git LFS..."
      git lfs install

      # Common game development file types for LFS
      echo "📁 Configuring LFS for game assets..."

      # Unreal Engine specific files
      git lfs track "*.uasset"
      git lfs track "*.umap"

      # 3D models and textures
      git lfs track "*.fbx"
      git lfs track "*.3ds"
      git lfs track "*.obj"
      git lfs track "*.blend"
      git lfs track "*.max"
      git lfs track "*.ma"
      git lfs track "*.mb"

      # Images
      git lfs track "*.psd"
      git lfs track "*.png"
      git lfs track "*.jpg"
      git lfs track "*.jpeg"
      git lfs track "*.tiff"
      git lfs track "*.tga"
      git lfs track "*.hdr"
      git lfs track "*.exr"

      # Audio files
      git lfs track "*.wav"
      git lfs track "*.mp3"
      git lfs track "*.ogg"
      git lfs track "*.flac"
      git lfs track "*.aiff"

      # Video files
      git lfs track "*.mp4"
      git lfs track "*.mov"
      git lfs track "*.avi"
      git lfs track "*.mkv"

      # Archives and binaries
      git lfs track "*.zip"
      git lfs track "*.7z"
      git lfs track "*.rar"
      git lfs track "*.dll"
      git lfs track "*.so"
      git lfs track "*.dylib"

      # Add .gitattributes to track LFS files
      git add .gitattributes

      echo "✅ Git LFS configured for game development!"
      echo "📁 Large binary files will be tracked with LFS"
      echo ""
      echo "💡 Next steps:"
      echo "  - Commit .gitattributes: git commit -m 'Configure Git LFS for game assets'"
      echo "  - All future binary assets will be automatically tracked"
    '')

    (writeShellScriptBin "init-project" ''
            #!/usr/bin/env bash
            set -euo pipefail

            # Project initialization script for different types
            case "''${1:-}" in
              "unreal"|"ue5")
                echo "🎮 Unreal Engine Project Setup"
                echo "════════════════════════════"
                echo ""
                echo "🔧 Setting up development environment..."

                # Initialize Git if not already done
                if [ ! -d ".git" ]; then
                  git init
                  echo "📝 Initialized Git repository"
                fi

                # Set up Git LFS for game development
                git-game-setup

                # Create basic project structure for UE5
                mkdir -p {Content,Source,Config,Plugins}

                # Create a basic .gitignore for Unreal projects
                cat > .gitignore << 'EOF'
      # Unreal Engine
      /Binaries/
      /Build/
      /DerivedDataCache/
      /Intermediate/
      /Saved/
      /.vs/
      /.vscode/

      # OS generated files
      .DS_Store
      .DS_Store?
      ._*
      .Spotlight-V100
      .Trashes
      ehthumbs.db
      Thumbs.db

      # IDE files
      *.sln
      *.suo
      *.xcodeproj
      *.xcworkspace
      EOF

                echo "📁 Created project structure"
                echo "🎯 Ready for Unreal Engine development!"
                echo ""
                echo "Next steps:"
                echo "  1. Open Epic Games Launcher"
                echo "  2. Create new UE5 project in this directory"
                echo "  3. Choose C++ project template"
                echo "  4. Start developing!"
                ;;
              *)
                echo "🚀 Available project types:"
                echo "  init-project unreal  - Unreal Engine 5 project setup"
                echo ""
                echo "Usage: init-project <type> [name]"
                ;;
            esac
    '')
  ];
}
