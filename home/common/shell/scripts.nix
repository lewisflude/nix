{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    (writeShellScriptBin "system-update" ''
      #!/bin/sh
      # system-update: Fast NixOS system update script
      # Usage: system-update [options]
      #   --full      Do a complete update (flake update + GC)
      #   --inputs    Update flake inputs
      #   --gc        Run garbage collection
      #   --help      Show this help

      set -e # Exit on error

      FLAKE_PATH="${config.home.homeDirectory}/.dotfiles"
      UPDATE_INPUTS=0
      RUN_GC=0
      BUILD_ONLY=0

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
        sudo nixos-rebuild build --flake "$FLAKE_PATH"#jupiter

        echo "🏠 Building home-manager configuration (without activating)..."
        home-manager build --flake "$FLAKE_PATH"#lewis@jupiter
      else
        echo "⚙️ Building and activating system configuration..."
        sudo nixos-rebuild switch --flake "$FLAKE_PATH"#jupiter

        echo "🏠 Updating home-manager configuration..."
        home-manager switch --flake "$FLAKE_PATH"#lewis@jupiter
      fi

      # Run garbage collection only when requested
      if [ $RUN_GC -eq 1 ]; then
        echo "🧹 Running garbage collection..."
        nix-collect-garbage -d
      fi

      echo "✨ System update complete!"

      # Print current system and home-manager generations
      echo "Current system generation:"
      sudo nix-env -p /nix/var/nix/profiles/system --list-generations | tail -n 1

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
    (writeShellScriptBin "gaming-mode" ''
      #!/usr/bin/env bash

      GAMING_MODE_FILE="/tmp/gaming-mode"

      toggle_gaming_mode() {
          if [ -f "$GAMING_MODE_FILE" ]; then
              # Disable gaming mode
              rm "$GAMING_MODE_FILE"

              # Reset system settings
              hyprctl keyword misc:vrr 1
              powerprofilesctl set balanced
              ratbagctl profile active default

              # Reset CPU governor
              echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

              # Reset GPU settings if NVIDIA
              if command -v nvidia-smi &> /dev/null; then
                  nvidia-smi -pm 0
                  nvidia-settings -a "GPUPowerMizerMode=0"
              fi

              notify-send "Gaming Mode" "Disabled" -i "󰊵"
          else
              # Enable gaming mode
              touch "$GAMING_MODE_FILE"

              # Set gaming optimizations
              hyprctl keyword misc:vrr 1
              powerprofilesctl set performance
              ratbagctl profile active gaming

              # Set CPU governor to performance
              echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

              # Set GPU settings if NVIDIA
              if command -v nvidia-smi &> /dev/null; then
                  nvidia-smi -pm 1
                  nvidia-settings -a "GPUPowerMizerMode=1"
              fi

              notify-send "Gaming Mode" "Enabled" -i "󰊴"
          fi
      }

      # Run the toggle function
      toggle_gaming_mode
    '')
  ];
}
