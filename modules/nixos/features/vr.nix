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
      };
    };

    # Steam configuration for VR
    programs.steam = mkIf config.host.features.gaming.steam {
      # SteamVR support packages
      extraPackages = mkIf cfg.steamvr [
        pkgs.openxr-loader
        pkgs.pipewire
      ];

      # Steam wrapper: Ensure XR_RUNTIME_JSON doesn't override system OpenXR runtime
      # The nixpkgs-xr overlay sets XR_RUNTIME_JSON to standalone Monado in dev shells,
      # but we need Steam to use the system's active_runtime.json (WiVRn) instead.
      # Also ensure NVIDIA encoding libraries are accessible for Remote Play streaming
      # This wrapper handles both VR and Remote Play streaming requirements
      package = pkgs.steam.overrideAttrs (oldAttrs: {
        buildCommand = (oldAttrs.buildCommand or "") + ''
          wrapProgram $out/bin/steam \
            --unset XR_RUNTIME_JSON \
            --set LD_LIBRARY_PATH "${config.hardware.nvidia.package}/lib:''${LD_LIBRARY_PATH:-}" \
            --set __GLX_VENDOR_LIBRARY_NAME "nvidia" \
            --set GBM_BACKEND "nvidia-drm"
        '';
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
      });
    };

    # Firewall for ALVR
    networking.firewall = mkIf cfg.alvr {
      allowedTCPPorts = [
        9943 # Control channel
        9944 # Streaming
      ];
      allowedUDPPorts = [
        9943 # Discovery
        9944 # Video/Audio streaming
      ];
    };

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
  };
}
