{ pkgs, config, ... }:
let
  steamRunUrl = pkgs.writeShellApplication {
    name = "steam-run-url";
    text = ''
      echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
    '';
    runtimeInputs = [ pkgs.coreutils ];
  };

  # Helper script to install Media Foundation codecs for Proton/Steam games
  # Media Foundation is required for proper video codec support in Windows games
  install-mf-codecs-proton = pkgs.writeShellApplication {
    name = "install-mf-codecs-proton";
    text = ''
      set -euo pipefail

      if [ $# -eq 0 ]; then
        echo "Error: Steam App ID required"
        echo ""
        echo "Usage: install-mf-codecs-proton <STEAM_APP_ID>"
        echo ""
        echo "Examples:"
        echo "  install-mf-codecs-proton 1234567"
        echo ""
        echo "To find your Steam App ID:"
        echo "  1. Right-click game in Steam → Properties → General"
        echo "  2. Look at the URL: steam://run/APP_ID"
        echo "  3. Or check: ${config.xdg.dataHome}/Steam/steamapps/"
        echo ""
        exit 1
      fi

      APP_ID="$1"
      echo "Installing Media Foundation codecs for Steam App ID: $APP_ID"
      echo "This may take several minutes..."

      ${pkgs.protontricks}/bin/protontricks "$APP_ID" -q mf

      echo ""
      echo "Media Foundation codecs installed successfully!"
      echo "You may need to restart the game for the changes to take effect."
    '';
    runtimeInputs = [
      pkgs.protontricks
    ];
  };

  # Lutris wrapper to ensure ESYNC limits are set explicitly
  # System-wide limits are configured in modules/nixos/features/gaming.nix
  # but this ensures limits are set even if launched outside systemd scope
  # Also sets explicit Vulkan ICD path to prevent GPU detection failures
  lutris-systemd = pkgs.writeShellScriptBin "lutris-systemd" ''
    # Explicitly set NVIDIA Vulkan ICD to prevent intermittent detection failures
    # This fixes "GPU outdated" errors caused by Vulkan loader timing issues
    export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.i686.json

    # Ensure DXVK uses the correct Vulkan device (fix for multi-GPU systems)
    export DXVK_FILTER_DEVICE_NAME="NVIDIA"

    exec ${pkgs.systemd}/bin/systemd-run --user --scope \
      --property="LimitNOFILE=1048576:1048576" \
      ${pkgs.lutris}/bin/lutris "$@"
  '';

  # Steam wrapper for Sunshine streaming (optional)
  # This wrapper can be used by Sunshine if you want to ensure Steam launches
  # with specific environment variables. For moving to HDMI-A-4, use Mod+Shift+S
  # after Steam launches, or configure Sunshine to use this wrapper and move manually.
  steam-sunshine = pkgs.writeShellScriptBin "steam-sunshine" ''
    # Launch Steam with any additional environment variables if needed
    exec ${pkgs.steam}/bin/steam "$@"
  '';

  # Helper script to show niri outputs with details
  # Useful for seeing the dummy HDMI-A-4 output used for Sunshine streaming
  show-niri-outputs = pkgs.writeShellApplication {
    name = "show-niri-outputs";
    text = ''
          echo "=== Niri Outputs ==="
          echo ""
          ${pkgs.niri}/bin/niri msg outputs --json | ${pkgs.jq}/bin/jq -r '
            .[] |
            "Output: \(.name)
      Resolution: \(.mode.width)x\(.mode.height) @ \(.mode.refresh)Hz
      Scale: \(.scale)
      Position: (\(.logical-position.x), \(.logical-position.y))
      Physical: \(if .physical-size then "\(.physical-size.width)x\(.physical-size.height)mm" else "N/A" end)
      \(if .name == "HDMI-A-4" then "⚠️  DUMMY OUTPUT (Sunshine streaming)" else "" end)
      "
          '
          echo ""
          echo "Focused output:"
          ${pkgs.niri}/bin/niri msg focused-output --json | ${pkgs.jq}/bin/jq -r '.name'
    '';
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
    ];
  };
in
{
  programs.mangohud = {
    enable = true;
    package = pkgs.mangohud;
    enableSessionWide = false; # Only enable when needed via env var
  };

  home.packages = [
    # User-facing gaming applications
    # Note: protonup-qt is provided at system level
    # Note: sunshine service is configured at system level
    pkgs.moonlight-qt
    pkgs.wine
    pkgs.winetricks
    steamRunUrl
    lutris-systemd
    steam-sunshine
    show-niri-outputs
    install-mf-codecs-proton
  ];

  # Override desktop entry to use wrapper with ESYNC limits
  xdg.desktopEntries.lutris = {
    name = "Lutris";
    exec = "${lutris-systemd}/bin/lutris-systemd %U";
    icon = "lutris";
    categories = [ "Game" ];
    mimeType = [
      "x-scheme-handler/lutris"
      "application/x-lutris-game"
    ];
    terminal = false;
    type = "Application";
  };

  # Auto-start Steam on login
  # Works in conjunction with system-level auto-login configured in host configuration
  systemd.user.services.steam-autostart = {
    Unit = {
      Description = "Auto-start Steam on login";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.steam}/bin/steam -silent";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
