# Virtual Monitors for VR Productivity Configuration
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
  # constants = import ../../../lib/constants.nix;
in
lib.mkIf (cfg.enable && cfg.virtualMonitors.enable) {
  # Virtual Monitors for VR Productivity (Immersed)
  # Hardware-based solution using dummy HDMI/DisplayPort adapters
  # On Wayland, this is currently the most robust solution until native protocol support
  # Diagnostic tools for virtual monitor detection and configuration
  environment.systemPackages =
    lib.optionals cfg.virtualMonitors.diagnosticTools [
      pkgs.pciutils # lspci for GPU/video output detection
      pkgs.wlr-randr # Wayland equivalent of xrandr for display management
    ]
    ++ [
      # Virtual monitor detection and setup helper script
      (pkgs.writeShellScriptBin "vr-detect-displays" ''
        #!/usr/bin/env bash
        # Virtual Monitor Detection Script for VR Setup
        # Detects GPU, display outputs, and dummy adapters

        set -euo pipefail

        echo "=== VR Virtual Monitor Detection ==="
        echo

        # Detect GPU(s)
        echo "🎮 Graphics Cards:"
        if command -v lspci &>/dev/null; then
          ${pkgs.pciutils}/bin/lspci | grep -i vga || echo "  ⚠️  No VGA devices found"
        else
          echo "  ⚠️  lspci not available"
        fi
        echo

        # Detect display server type
        echo "🖥️  Display Server:"
        if [ -n "''${WAYLAND_DISPLAY:-}" ] || [ "''${XDG_SESSION_TYPE:-}" = "wayland" ]; then
          echo "  ✅ Wayland detected"
          echo "     Session: ''${XDG_SESSION_TYPE:-unknown}"
          echo "     Display: ''${WAYLAND_DISPLAY:-unknown}"
        elif [ -n "''${DISPLAY:-}" ]; then
          echo "  ✅ X11 detected"
          echo "     Display: ''${DISPLAY}"
        else
          echo "  ⚠️  No display server detected"
        fi
        echo

        # Detect connected displays (Wayland)
        if command -v wlr-randr &>/dev/null && [ -n "''${WAYLAND_DISPLAY:-}" ]; then
          echo "📺 Connected Displays (wlr-randr):"
          ${pkgs.wlr-randr}/bin/wlr-randr || echo "  ⚠️  Failed to query displays"
          echo
        fi

        # Detect connected displays (X11)
        if command -v xrandr &>/dev/null && [ -n "''${DISPLAY:-}" ]; then
          echo "📺 Connected Displays (xrandr):"
          xrandr | grep -E "connected|disconnected" || echo "  ⚠️  Failed to query displays"
          echo
        fi

        # Configuration recommendations
        echo "💡 Configuration Recommendations:"
        echo
        echo "Current config: features.vr.virtualMonitors ="
        echo "  enable = true;"
        echo "  method = "${cfg.virtualMonitors.method}";"
        echo "  hardwareAdapterCount = ${toString cfg.virtualMonitors.hardwareAdapterCount};"
        echo "  defaultResolution = "${cfg.virtualMonitors.defaultResolution}";"
        echo
        echo "📖 For setup instructions, see: docs/VR_SETUP_GUIDE.md"
        echo

        # Hardware adapter recommendations
        if [ "${cfg.virtualMonitors.method}" = "hardware" ]; then
          echo "🔌 Hardware Method Selected:"
          echo "  - You need ${toString cfg.virtualMonitors.hardwareAdapterCount} dummy HDMI/DisplayPort adapters"
          echo "  - Search for: '4K headless ghost adapter' or 'HDMI dummy plug'"
          echo "  - Recommended: Adapters with EDID chip for 4K support"
          echo "  - Cost: ~\$10-20 per adapter"
          echo
          echo "  Popular options:"
          echo "  - Headless Ghost 4K (search on Amazon/AliExpress)"
          echo "  - FUERAN 4K HDMI Dummy Plug"
          echo "  - Any EDID emulator with 3840x1600+ support"
          echo
        fi

        echo "✅ Detection complete!"
      '')
    ];

  # Documentation and assertions for hardware method
  assertions = lib.optionals (cfg.virtualMonitors.method == "hardware") [
    {
      assertion = cfg.virtualMonitors.hardwareAdapterCount > 0;
      message = ''
        Virtual monitors with hardware method requires at least 1 dummy adapter.
        Set features.vr.virtualMonitors.hardwareAdapterCount to the number of adapters you have.
      '';
    }
  ];
}
