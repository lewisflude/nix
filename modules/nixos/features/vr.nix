{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.lists) optionals;
  cfg = config.host.features.vr;
  constants = import ../../../lib/constants.nix;
in
{
  config = mkIf cfg.enable {
    # Services configuration
    services = {
      # OpenXR runtime (Monado) - required for VR on Linux
      monado = mkIf cfg.monado {
        enable = true;
        defaultRuntime = !cfg.wivrn.enable || !cfg.wivrn.defaultRuntime;
        highPriority = cfg.performance;
      };

      # WiVRn - OpenXR streaming server built on Monado
      wivrn = mkIf cfg.wivrn.enable {
        enable = true;
        inherit (cfg.wivrn) defaultRuntime autoStart openFirewall;
      };

      # Udev rules for Meta Quest devices
      udev = {
        packages = [
          (pkgs.writeTextFile {
            name = "meta-quest-udev-rules";
            destination = "/etc/udev/rules.d/99-meta-quest.rules";
            text = ''
              # Meta Quest 1/2/3/Pro - Vendor ID 2833 (Meta/Oculus)
              SUBSYSTEM=="usb", ATTR{idVendor}=="2833", MODE="0666", GROUP="plugdev", TAG+="uaccess"
            '';
          })
        ];

        # Disable USB autosuspend for Quest (prevents disconnects)
        extraRules = ''
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2833", TEST=="power/control", ATTR{power/control}="on"
        '';
      };

      # Process priority for VR applications
      ananicy = mkIf (cfg.performance && config.services.ananicy.enable) {
        extraRules = [
          # ALVR streaming
          {
            name = "alvr_server";
            type = "RT";
            nice = -10;
            ioclass = "realtime";
          }
          {
            name = "vrserver";
            type = "RT";
            nice = -10;
            ioclass = "realtime";
          }
          # Monado OpenXR
          {
            name = "monado-service";
            type = "RT";
            nice = -10;
            ioclass = "realtime";
          }
          # WiVRn streaming
          {
            name = "wivrn-server";
            type = "RT";
            nice = -10;
            ioclass = "realtime";
          }
          # SteamVR
          {
            name = "vrcompositor";
            type = "RT";
            nice = -10;
            ioclass = "realtime";
          }
          {
            name = "vrdashboard";
            type = "Player";
            nice = -5;
          }
        ];
      };
    };

    # Monado environment variables (systemd user service)
    systemd.user.services.monado = mkIf cfg.monado {
      environment = {
        # Enable SteamVR lighthouse tracking
        STEAMVR_LH_ENABLE = "1";
        # Use compute shaders for compositor (better performance)
        XRT_COMPOSITOR_COMPUTE = "1";
        # Disable hand tracking (requires downloading models separately)
        # To enable: mkdir -p ~/.local/share/monado && cd ~/.local/share/monado
        #            git clone https://gitlab.freedesktop.org/monado/utilities/hand-tracking-models
        WMR_HANDTRACKING = "0";
        # Fix headset view stuttering (recommended by LVRA)
        U_PACING_COMP_MIN_TIME_MS = "5";

        # NVIDIA-specific VR optimizations (2026 best practices)
        # Disable VSync - VR compositor handles frame timing
        __GL_SYNC_TO_VBLANK = "0";
        # Reduce input latency by limiting render-ahead queue
        __GL_MaxFramesAllowed = "1";
        # Enable VRR for VR headset (if supported)
        __GL_VRR_ALLOWED = "1";

        # Monado performance tuning
        XRT_COMPOSITOR_FORCE_RANDR = "0"; # Disable RandR on Wayland
        U_PACING_APP_MIN_TIME_MS = "2"; # Minimum app frame time for low latency
      };
    };

    # Steam configuration for VR
    programs.steam = mkIf config.host.features.gaming.steam {
      # SteamVR support packages
      extraPackages = mkIf cfg.steamvr [
        pkgs.openxr-loader
        pkgs.pipewire
      ];

      # OpenXR runtime integration for VR games
      # Overrides gaming.nix's Steam package (which uses mkDefault) to add VR support
      # Includes all gaming.nix settings plus VR-specific configuration
      package = pkgs.steam.override {
        extraEnv = {
          # From gaming.nix - Force Steam to use PipeWire for screen capture on Wayland
          STEAM_FORCE_DESKTOPUI_SCALING = "1";
        };
        extraArgs = "-pipewire";
        extraProfile = ''
          # VR-specific: Import OpenXR runtimes into Steam's pressure-vessel container
          # This allows Steam games to detect and use Monado/WiVRn OpenXR runtimes
          export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1

          # VR-specific: Fix timezone issues in VR games
          # Some VR games have timezone handling bugs that cause crashes
          unset TZ

          # Note: For OpenXR games launched through Steam, you may need to add launch options:
          #   PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/monado_comp_ipc %command%
          # Or for WiVRn:
          #   PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
          # This grants Steam's pressure-vessel container access to the OpenXR runtime socket
        '';
      };
    };

    # Firewall configuration for VR streaming
    networking.firewall = lib.mkMerge [
      # WiVRn ports (required for Quest 3 discovery and streaming)
      (mkIf cfg.wivrn.enable {
        allowedTCPPorts = [
          constants.ports.vr.wivrn.tcp # WiVRn streaming (TCP)
        ];
        allowedUDPPorts = [
          constants.ports.vr.mdns # mDNS discovery (Avahi/Bonjour) - Quest 3 server discovery
          constants.ports.vr.wivrn.udp # WiVRn streaming (UDP)
        ];
      })

      # ALVR ports (only if ALVR is enabled)
      (mkIf cfg.alvr {
        allowedTCPPorts = [
          constants.ports.vr.alvr.control # ALVR Control channel
          constants.ports.vr.alvr.stream # ALVR Streaming
        ];
        allowedUDPPorts = [
          constants.ports.vr.alvr.control # ALVR Discovery
          constants.ports.vr.alvr.stream # ALVR Video/Audio streaming
        ];
      })
    ];

    # System packages
    environment.systemPackages = [
      pkgs.android-tools
    ]
    ++ optionals cfg.alvr [
      pkgs.alvr
      pkgs.zenity # Required for ALVR's SteamVR launch dialog
    ]
    ++ optionals cfg.sidequest [ pkgs.sidequest ]
    ++ optionals cfg.opencomposite [ pkgs.opencomposite ];

    # NVIDIA optimizations
    hardware.nvidia = mkIf (cfg.performance && config.hardware.nvidia.modesetting.enable) {
      powerManagement.finegrained = false;
      nvidiaPersistenced = true;
    };

    # Graphics requirements
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    assertions = [
      {
        assertion = cfg.steamvr -> config.host.features.gaming.steam;
        message = "SteamVR requires Steam (host.features.gaming.steam)";
      }
      {
        assertion = cfg.wivrn.enable -> (cfg.monado || cfg.wivrn.defaultRuntime);
        message = "WiVRn requires either Monado enabled or WiVRn as default runtime";
      }
      {
        assertion = cfg.opencomposite -> (cfg.monado || cfg.wivrn.enable);
        message = "OpenComposite requires an OpenXR runtime (Monado or WiVRn)";
      }
    ];

    # Niri compositor limitations for VR
    # Note: Niri is a scrollable tiling Wayland compositor and does not currently have
    # documented support for VR desktop overlays (wlx-overlay-s). VR games should work,
    # but desktop overlay features may be limited or non-functional. For full VR desktop
    # integration, consider using a compositor with explicit VR overlay support.
    warnings = lib.optionals (config.host.features.desktop.niri && cfg.enable) [
      "VR is enabled with Niri compositor. VR games should work, but desktop overlays (wlx-overlay-s) may have limited functionality."
    ];
  };
}
