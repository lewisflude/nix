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

  # ALVR wrapper with VR-optimized environment variables
  # This keeps VR settings isolated from other applications
  alvrWrapped = pkgs.writeShellScriptBin "alvr" ''
    # VR-specific NVIDIA optimizations (don't affect other apps)
    export __GL_SYNC_TO_VBLANK=0
    export __GL_THREADED_OPTIMIZATIONS=1
    export __GL_SHADER_DISK_CACHE=0  # VR needs consistent frame times

    exec ${pkgs.alvr}/bin/alvr_dashboard "$@"
  '';
in
{
  config = mkIf cfg.enable {
    # Services configuration
    services = {
      # OpenXR runtime (Monado) - required for VR on Linux
      monado = mkIf cfg.monado {
        enable = true;
        defaultRuntime = true;
        highPriority = cfg.performance;
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

    # SteamVR support
    programs.steam = mkIf (cfg.steamvr && config.host.features.gaming.steam) {
      extraPackages = [
        pkgs.openxr-loader
        pkgs.pipewire
      ];
    };

    # Firewall for ALVR
    networking.firewall = mkIf cfg.alvr {
      allowedTCPPorts = [
        9943
        9944
      ];
      allowedUDPPorts = [
        9943
        9944
      ];
    };

    # System packages
    environment.systemPackages = [
      pkgs.android-tools
    ]
    ++ optionals cfg.alvr [ alvrWrapped ]
    ++ optionals cfg.sidequest [ pkgs.sidequest ];

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
    ];
  };
}
