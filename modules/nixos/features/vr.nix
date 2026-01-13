{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
  constants = import ../../../lib/constants.nix;
in
{
  config = lib.mkMerge [
    # Base VR configuration (always applied when vr.enable = true)
    (lib.mkIf cfg.enable {
      # Enable Monado OpenXR runtime
      # Monado is the native open-source OpenXR runtime for Linux
      # It provides VR/AR support on Wayland with excellent performance
      services.monado = lib.mkIf cfg.monado {
        enable = true;
        defaultRuntime = !cfg.wivrn.enable || !cfg.wivrn.defaultRuntime;
        highPriority = cfg.performance; # Enable high priority for better frame timing
      };

      # VR user applications and tools
      environment.systemPackages =
        # SideQuest for Quest device sideloading
        # Wrapped with compiled GTK schemas to fix file chooser crashes
        lib.optionals cfg.sidequest [
          (pkgs.runCommand "sidequest-with-gtk"
            {
              nativeBuildInputs = [
                pkgs.makeWrapper
                pkgs.glib
              ];
              inherit (pkgs.sidequest) meta;
            }
            ''
              mkdir -p $out/bin $out/share/gsettings-schemas/sidequest-with-gtk/glib-2.0/schemas

              # Copy all schema files
              cp ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml \
                 $out/share/gsettings-schemas/sidequest-with-gtk/glib-2.0/schemas/ 2>/dev/null || true
              cp ${pkgs.gtk3}/share/gsettings-schemas/*/glib-2.0/schemas/*.xml \
                 $out/share/gsettings-schemas/sidequest-with-gtk/glib-2.0/schemas/ 2>/dev/null || true

              # Compile the schemas
              glib-compile-schemas $out/share/gsettings-schemas/sidequest-with-gtk/glib-2.0/schemas

              # Create wrapper
              makeWrapper ${pkgs.sidequest}/bin/sidequest $out/bin/sidequest \
                --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/sidequest-with-gtk"
            ''
          )
        ]
        # Quest 3 Core Tooling (nixpkgs-xr packages)
        # xrizer: Modern SteamVR->OpenXR translation (replaces OpenComposite)
        # Use as Steam launch option: xrizer %command%
        ++ [ pkgs.xrizer ]
        # Resonite Tools
        # resolute: Mod manager for Resonite
        # oscavmgr: Face/Eye/Avatar tracking data manager (OSC protocol)
        ++ [
          pkgs.resolute
          pkgs.oscavmgr
        ]
        # Note: proton-ge-rtsp-bin is not added to systemPackages as it's a single binary
        # If needed for VRChat/Resonite video streams, install it as a Steam compatibility tool
        # Advanced VR Tools (nixpkgs-xr)
        # kaon: UEVR manager for flat-to-VR game injection
        # vapor: Lightweight VR home/launcher
        # xrbinder: Controller remapping utility
        # lovr: Lua-based VR development engine
        ++ [
          pkgs.kaon
          pkgs.vapor
          pkgs.xrbinder
          pkgs.lovr
        ]
        # Legacy OpenComposite support (optional, prefer xrizer)
        # OpenComposite - OpenVR to OpenXR translation layer
        # Note: xrizer is the modern replacement and should be preferred
        ++ lib.optionals cfg.opencomposite [ pkgs.opencomposite ];

      # Steam VR support - configure Steam FHS for OpenXR
      # This overrides the gaming module's Steam package to add VR-specific configuration
      programs.steam.package = lib.mkIf (config.host.features.gaming.steam or false) (
        pkgs.steam.override {
          extraProfile = ''
            # Fixes timezones in VRChat and Resonite
            # These social VR apps read TZ and can show incorrect times
            unset TZ

            # Allows OpenXR runtime to be discovered by sandboxed Steam games
            # Without this, Steam's pressure-vessel container cannot find Monado
            export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
          '';
        }
      );
    })

    # WiVRn wireless VR streaming configuration
    # WiVRn enables wireless PCVR from Quest headsets over WiFi
    # It wraps Monado and provides network streaming capabilities
    (lib.mkIf (cfg.enable && cfg.wivrn.enable) {
      services.wivrn = {
        enable = true;
        inherit (cfg.wivrn) autoStart defaultRuntime openFirewall;
        highPriority = cfg.performance; # Enable async reprojection with high priority

        # Enable CUDA support for NVIDIA GPUs (RTX 4090)
        # This provides hardware-accelerated video encoding for VR streaming
        package = pkgs.wivrn.override { cudaSupport = true; };

        # Monado environment variables for better performance
        monadoEnvironment = lib.mkIf cfg.performance {
          # Minimum time between compositor frames (milliseconds)
          # Lower values reduce latency but increase CPU usage
          # Reduced to 2ms for VR desktop overlay responsiveness
          U_PACING_COMP_MIN_TIME_MS = "2";

          # Exit Monado when all VR applications disconnect
          # Useful for wireless VR to save resources when not in use
          IPC_EXIT_ON_DISCONNECT = if cfg.wivrn.autoStart then "1" else "0";

          # NVIDIA NVENC low-latency encoding (for RTX 4090)
          # Reduces encoding latency for wireless streaming
          WIVRN_ENCODER_PRESET = "p1"; # Ultra low latency preset (was p4)
          WIVRN_ENCODER_RC_MODE = "cbr"; # Constant bitrate for consistent latency
        };
      };
    })

    # Virtual Monitors for VR Productivity (Immersed)
    # Hardware-based solution using dummy HDMI/DisplayPort adapters
    # On Wayland, this is currently the most robust solution until native protocol support
    (lib.mkIf (cfg.enable && cfg.virtualMonitors.enable) {
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
            echo "  method = \"${cfg.virtualMonitors.method}\";"
            echo "  hardwareAdapterCount = ${toString cfg.virtualMonitors.hardwareAdapterCount};"
            echo "  defaultResolution = \"${cfg.virtualMonitors.defaultResolution}\";"
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
    })

    # Immersed VR desktop productivity application
    # Provides virtual monitors in VR for working in mixed reality
    (lib.mkIf (cfg.enable && cfg.immersed.enable) {
      # Use native NixOS module for Immersed
      # Wrapped to use XWayland on Niri (workaround for wl_output protocol bug)
      programs.immersed = {
        enable = true;
        # Force XWayland for compatibility with Niri compositor
        # Immersed has a bug where it binds to wl_output version 1 but doesn't
        # handle the 'done' event (opcode 2) added in version 2, causing:
        # "listener function for opcode 2 of wl_output is NULL"
        # This is fixed in Immersed on GNOME Wayland but not Niri yet.
        #
        # Also disable VAAPI (Intel/AMD video acceleration) which:
        # 1. Doesn't work on NVIDIA GPUs anyway
        # 2. Causes GStreamer gst_util_floor_log2 symbol errors
        # NVIDIA uses NVDEC/NVENC for hardware acceleration, not VAAPI
        #
        # Additional fixes for OAuth sign-in and rendering:
        # - webkit2gtk-4.1: Embedded browser for OAuth authentication
        # - libsecret: Credential storage (AppImages need system libsecret)
        # - gnome-keyring: Keyring daemon for secure credential storage
        # - LD_LIBRARY_PATH: Make system libraries available to AppImage
        #
        # Force XWayland due to wl_output protocol bug:
        # - Immersed binds to wl_output version 1 but doesn't handle the 'done' event (opcode 2)
        #   added in version 2, causing: "listener function for opcode 2 of wl_output is NULL"
        # - Fixed in Immersed on GNOME Wayland but NOT on Niri as of 2026-01-12
        # - Must use XWayland until Immersed fixes wl_output protocol handling
        #
        # DPI/Scaling fixes for XWayland with fractional scaling (1.25x):
        # - GDK_SCALE=2: GTK base scaling (2x for HiDPI)
        # - GDK_DPI_SCALE=0.625: Fine-tune to 1.25x total (2 * 0.625 = 1.25)
        # - ELECTRON_OZONE_PLATFORM_HINT: Tell Electron to use Ozone (even via XWayland)
        # - --force-device-scale-factor=1.25: Explicitly set Electron's UI scaling
        # - --enable-features=UseOzonePlatform: Enable Ozone platform layer
        # - --ozone-platform-hint=auto: Let Electron choose best platform (X11 via Ozone)
        # Alternative if above doesn't work: Use GDK_SCALE=1 + --force-device-scale-factor=1.5
        #
        # VAAPI disabled for NVIDIA compatibility:
        # - NVIDIA uses NVDEC/NVENC, not VAAPI
        # - Prevents GStreamer symbol errors
        package =
          let
            # Explicitly override Immersed to use latest version
            # The overlay should handle this, but we're being explicit here
            immersedLatest = pkgs.immersed.overrideAttrs (_: {
              version = "11.0.0-latest";
              src = pkgs.fetchurl {
                url = "https://static.immersed.com/dl/Immersed-x86_64.AppImage";
                hash = "sha256-GbckZ/WK+7/PFQvTfUwwePtufPKVwIwSPh+Bo/cG7ko=";
              };
            });
          in
          pkgs.symlinkJoin {
            name = "immersed-xwayland-nvidia";
            paths = [ immersedLatest ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/immersed \
                --unset WAYLAND_DISPLAY \
                --set ELECTRON_OZONE_PLATFORM_HINT "auto" \
                --set LIBVA_DRIVER_NAME "none" \
                --set LIBVA_DRIVERS_PATH "/nonexistent" \
                --set XDG_SESSION_TYPE "x11" \
                --set GDK_SCALE "2" \
                --set GDK_DPI_SCALE "0.625" \
                --set GTK_THEME "Adwaita:dark" \
                --set GTK_USE_PORTAL "1" \
                --add-flags "--force-device-scale-factor=1.25" \
                --add-flags "--enable-features=UseOzonePlatform" \
                --add-flags "--ozone-platform-hint=auto" \
                --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
                --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}" \
                --prefix LD_LIBRARY_PATH : "${
                  pkgs.lib.makeLibraryPath [
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

      # Ensure gnome-keyring is available for Immersed authentication
      # Immersed uses OAuth which requires secure credential storage
      services.gnome.gnome-keyring.enable = lib.mkDefault true;
      security.pam.services.login.enableGnomeKeyring = lib.mkDefault true;

      # Firewall configuration for Immersed
      # Immersed uses these ports for communication between PC and headset
      networking.firewall = lib.mkIf cfg.immersed.openFirewall {
        allowedTCPPorts = [
          constants.ports.vr.immersed.tcp.start # 5230
          (constants.ports.vr.immersed.tcp.start + 1) # 5231
          (constants.ports.vr.immersed.tcp.start + 2) # 5232
        ];
        allowedUDPPorts = [
          constants.ports.vr.immersed.udp.start # 5230
          (constants.ports.vr.immersed.udp.start + 1) # 5231
          (constants.ports.vr.immersed.udp.start + 2) # 5232
        ];
      };
    })

    # VR performance optimizations
    (lib.mkIf (cfg.enable && cfg.performance) {
      # NVIDIA-specific VR optimizations
      environment.sessionVariables = lib.mkIf config.hardware.nvidia.modesetting.enable {
        # Force GPU-accelerated XWayland for better VR performance
        # This ensures VR overlays and desktop views render efficiently
        XWAYLAND_NO_GLAMOR = "0";
      };

      # System-level optimizations for VR workloads
      boot.kernel.sysctl = {
        # Note: fs.inotify.max_user_watches is already set to 1048576 in memory.nix
        # which is sufficient for VR applications

        # Reduce swappiness for better real-time performance
        # VR requires consistent frame timing and should avoid swap
        "vm.swappiness" = 10;
      };
    })

    # ALVR (Air Light VR) - Alternative wireless VR streaming
    # Note: ALVR requires SteamVR, so it's incompatible with Monado-only setups
    # This option should be disabled when using WiVRn + Monado
    (lib.mkIf (cfg.enable && cfg.alvr) {
      environment.systemPackages = [ pkgs.alvr ];

      # ALVR firewall ports (if openFirewall equivalent existed)
      # These ports are used for ALVR streaming protocol
      networking.firewall = {
        allowedTCPPorts = [
          9943 # ALVR web server
          9944 # ALVR streaming
        ];
        allowedUDPPorts = [
          9943
          9944
        ];
      };
    })

    # SteamVR support (not recommended on Wayland)
    # SteamVR works poorly on Wayland and is proprietary
    # Monado + OpenComposite provides better performance and compatibility
    # This option should generally be disabled on NixOS
    (lib.mkIf (cfg.enable && cfg.steamvr) {
      # SteamVR is installed via Steam, so no additional packages needed
      # Just ensure Steam is enabled in gaming configuration
      assertions = [
        {
          assertion = config.host.features.gaming.steam or false;
          message = "SteamVR requires Steam to be enabled (host.features.gaming.steam = true)";
        }
      ];
    })
  ];
}
