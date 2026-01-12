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
        # Social VR Media Support
        # proton-ge-rtsp-bin: Required for VRChat/Resonite video streams
        ++ [ pkgs.proton-ge-rtsp-bin ]
        # Resonite Tools
        # resolute: Mod manager for Resonite
        # oscavmgr: Face/Eye/Avatar tracking data manager (OSC protocol)
        ++ [
          pkgs.resolute
          pkgs.oscavmgr
        ]
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
          # 5ms is a good balance for most systems
          U_PACING_COMP_MIN_TIME_MS = "5";

          # Exit Monado when all VR applications disconnect
          # Useful for wireless VR to save resources when not in use
          IPC_EXIT_ON_DISCONNECT = if cfg.wivrn.autoStart then "1" else "0";
        };
      };
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
        # Additional fixes for OAuth sign-in on XWayland:
        # - webkit2gtk-4.1: Embedded browser for OAuth authentication
        # - libsecret: Credential storage (AppImages need system libsecret)
        # - gnome-keyring: Keyring daemon for secure credential storage
        # - LD_LIBRARY_PATH: Make system libraries available to AppImage
        # - XDG_SESSION_TYPE: Explicitly set to x11 for XWayland
        package = pkgs.symlinkJoin {
          name = "immersed-xwayland-nvidia";
          paths = [ pkgs.immersed ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/immersed \
              --unset WAYLAND_DISPLAY \
              --set LIBVA_DRIVER_NAME "none" \
              --set LIBVA_DRIVERS_PATH "/nonexistent" \
              --set XDG_SESSION_TYPE "x11" \
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
