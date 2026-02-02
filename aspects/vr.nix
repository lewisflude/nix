# VR Aspect
#
# Combines all VR-related configuration in a single file.
# Reads options from config.host.features.vr (defined in modules/shared/host-options/features/vr.nix)
#
# Platform support:
# - NixOS: WiVRn, SteamVR, Immersed, VR performance optimizations
# - Darwin: Immersed update helper script
{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkForce
    getExe'
    makeLibraryPath
    ;
  cfg = config.host.features.vr;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  # Darwin Immersed update helper
  immersedUrl = "https://static.immersed.com/dl/Immersed.dmg";
  appName = "Immersed";
  appPath = "/Applications/${appName}.app";
in
{
  config = mkMerge [
    # ================================================================
    # NixOS - WiVRn Configuration
    # ================================================================
    (mkIf (cfg.enable && cfg.wivrn.enable && isLinux) {
      # WiVRn wireless VR streaming configuration
      # Provides wireless PCVR from Quest headsets over WiFi using embedded Monado runtime
      # Following LVRA best practices: use defaults for best out-of-the-box performance

      # System-level packages for WiVRn (needed by wivrn-dashboard GUI)
      environment.systemPackages = [ pkgs.android-tools ];

      services.wivrn = {
        enable = true;
        package = pkgs.wivrn.override { cudaSupport = true; }; # Essential for RTX 4090
        inherit (cfg.wivrn) autoStart defaultRuntime openFirewall;
        highPriority = cfg.performance; # Enable async reprojection with high priority

        # Steam integration - automatically import OpenXR runtimes
        steam.importOXRRuntimes = true;
        config = {
          enable = true;
          json = {
            # WiVRn auto-detects optimal encoder settings based on hardware
            # RTX 4090 will automatically use NVENC with AV1 codec at 10-bit depth
            # Quest 3 hardware is automatically detected and optimized

            # Auto-launch WayVR when headset connects
            application = [ pkgs.wayvr ];
          };
        };
      };

      # NVIDIA GPU latency fixes for embedded Monado runtime
      # Addresses present latency issues with Nvidia driver 565+
      # See: https://lvra.gitlab.io/docs/hardware/
      systemd.services.wivrn.environment = {
        XRT_COMPOSITOR_USE_PRESENT_WAIT = "1";
        U_PACING_COMP_TIME_FRACTION_PERCENT = "90";
      };

      # Fix for upstream removal of --systemd flag
      # See: https://github.com/NixOS/nixpkgs/issues/482152
      # Workaround from: https://github.com/NixOS/nixpkgs/pull/480752
      # Remove the --systemd flag by overriding ExecStart
      systemd.user.services.wivrn = {
        # Add android-tools to PATH so wivrn-dashboard can find adb
        # This extends the existing path (which includes steam)
        path = lib.mkAfter [ pkgs.android-tools ];

        serviceConfig.ExecStart =
          let
            wivrnConfig = config.services.wivrn;
            configFile = pkgs.writeText "wivrn-config.json" (builtins.toJSON wivrnConfig.config.json);
          in
          mkForce "${getExe' wivrnConfig.package "wivrn-server"} -f ${configFile}";
      };
    })

    # ================================================================
    # NixOS - SteamVR Configuration
    # ================================================================
    (mkIf (cfg.enable && cfg.steamvr && isLinux) {
      # SteamVR support for 32-bit VR games
      # Note: WiVRn doesn't support 32-bit executables (e.g., Half Life 2 VR)
      # SteamVR is needed as a fallback for these games

      # Install SteamVR dependencies
      environment.systemPackages = [
        # SteamVR itself is installed via Steam client
        # These are the system-level dependencies needed
      ];

      # Ensure 32-bit graphics drivers are available (already in graphics.nix)
      # hardware.graphics.enable32Bit = true;

      # Note: SteamVR must be installed through the Steam client
      # It cannot be packaged directly in NixOS due to its proprietary nature
      # SteamVR async reprojection works without additional capabilities
    })

    # ================================================================
    # NixOS - Immersed Configuration
    # ================================================================
    (mkIf (cfg.enable && cfg.immersed.enable && isLinux) {
      programs.immersed = {
        enable = true;
        # Wrapper for Niri + NVIDIA compatibility
        # - XWayland: Immersed has wl_output protocol bug on Niri
        # - VAAPI disabled: NVIDIA uses NVDEC/NVENC, not VAAPI
        # - DPI scaling: 1.25x via GDK_SCALE=2 + GDK_DPI_SCALE=0.625
        package = pkgs.symlinkJoin {
          name = "immersed-xwayland-nvidia";
          paths = [ pkgs.immersed ]; # Uses overlay version
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/immersed \
              --unset WAYLAND_DISPLAY \
              --set XDG_SESSION_TYPE "x11" \
              --set LIBVA_DRIVER_NAME "none" \
              --set GDK_SCALE "2" \
              --set GDK_DPI_SCALE "0.625" \
              --set GTK_USE_PORTAL "1" \
              --add-flags "--force-device-scale-factor=1.25" \
              --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
              --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}" \
              --prefix LD_LIBRARY_PATH : "${
                makeLibraryPath [
                  pkgs.webkitgtk_4_1
                  pkgs.libsecret
                  pkgs.glib
                  pkgs.gtk3
                  pkgs.libsoup_3
                  pkgs.glib-networking
                ]
              }"
          '';
        };
      };

      # OAuth authentication requires keyring
      services.gnome.gnome-keyring.enable = lib.mkDefault true;
      security.pam.services.login.enableGnomeKeyring = lib.mkDefault true;

      # Firewall for PC-headset communication
      networking.firewall = mkIf cfg.immersed.openFirewall {
        allowedTCPPorts = [
          constants.ports.vr.immersed.tcpStart
          (constants.ports.vr.immersed.tcpStart + 1)
          (constants.ports.vr.immersed.tcpStart + 2)
        ];
        allowedUDPPorts = [
          constants.ports.vr.immersed.udpStart
          (constants.ports.vr.immersed.udpStart + 1)
          (constants.ports.vr.immersed.udpStart + 2)
        ];
      };
    })

    # ================================================================
    # NixOS - VR Performance Configuration
    # ================================================================
    (mkIf (cfg.enable && cfg.performance && isLinux) {
      # NVIDIA-specific: Force GPU-accelerated XWayland for VR overlays
      environment.sessionVariables = mkIf config.hardware.nvidia.modesetting.enable {
        XWAYLAND_NO_GLAMOR = "0";
      };

      # Note: fs.inotify.max_user_watches (1048576) is set in memory.nix
      # Note: vm.swappiness (10) is set in disk-performance.nix
    })

    # ================================================================
    # Darwin Configuration
    # ================================================================
    (mkIf (cfg.enable && cfg.immersed.enable && isDarwin) {
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "update-immersed-darwin" ''
          #!/bin/bash
          set -euo pipefail

          echo "Updating Immersed VR..."

          # Remove existing installation
          if [ -d "${appPath}" ]; then
            echo "Removing existing installation..."
            rm -rf "${appPath}"
          fi

          # Download fresh copy
          TMPDIR=$(mktemp -d)
          DMG_PATH="$TMPDIR/Immersed.dmg"

          echo "Downloading latest Immersed VR..."
          curl -fsSL "${immersedUrl}" -o "$DMG_PATH"

          echo "Mounting DMG..."
          MOUNT_POINT=$(mktemp -d)
          hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse -quiet

          echo "Installing ${appName}.app..."
          cp -R "$MOUNT_POINT/${appName}.app" /Applications/

          hdiutil detach "$MOUNT_POINT" -quiet
          rm -rf "$TMPDIR"

          echo "Immersed VR updated successfully!"
        '')
      ];
    })

    # ================================================================
    # Assertions (both platforms)
    # ================================================================
    {
      assertions = [
        {
          assertion = cfg.wivrn.enable -> cfg.enable;
          message = "WiVRn requires VR feature to be enabled";
        }
        {
          assertion = cfg.immersed.enable -> cfg.enable;
          message = "Immersed requires VR feature to be enabled";
        }
        {
          assertion = !(cfg.steamvr && isLinux) || config.host.features.gaming.steam;
          message = "SteamVR requires Steam to be enabled (features.gaming.steam = true)";
        }
        {
          assertion = !(cfg.wivrn.enable && isDarwin);
          message = "WiVRn is not available on macOS";
        }
        {
          assertion = !(cfg.steamvr && isDarwin);
          message = "SteamVR is not available on macOS";
        }
      ];
    }
  ];
}
