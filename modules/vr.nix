# VR Module - WiVRn + xrizer for Quest headsets
# References:
# - https://lvra.gitlab.io/docs/distros/nixos/
# - https://wiki.nixos.org/wiki/VR
#
# NOTE: VR also requires Steam integration configured in gaming.nix
# (PRESSURE_VESSEL env vars, xrizer in extraPkgs)
{ ... }:
{
  flake.modules.nixos.vr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.wivrn = {
        enable = true;
        defaultRuntime = true;
        openFirewall = true;
        autoStart = true;
        highPriority = true;
        steam.importOXRRuntimes = true;

        # NVIDIA VR environment from LVRA wiki
        monadoEnvironment = {
          XRT_COMPOSITOR_USE_PRESENT_WAIT = "1";
          U_PACING_COMP_TIME_FRACTION_PERCENT = "90";
          U_PACING_COMP_MIN_TIME_MS = "5";
          XRT_COMPOSITOR_FORCE_WAYLAND_DIRECT = "1";
          IPC_EXIT_ON_DISCONNECT = "1";
        };

        # Dual NVENC AV1 encoding: splits left/right eyes across RTX 4090's
        # two NVENC engines for concurrent encoding. AV1 10-bit gives best
        # quality per bit; Quest 3 has native AV1 HW decode.
        config = {
          enable = true;
          json = {
            application = [ pkgs.wayvr ];
            bit-depth = 10;
            encoder = [
              {
                encoder = "nvenc";
                codec = "av1";
                width = 0.5;
                height = 1.0;
                offset_x = 0.0;
                offset_y = 0.0;
                group = 0;
              }
              {
                encoder = "nvenc";
                codec = "av1";
                width = 0.5;
                height = 1.0;
                offset_x = 0.5;
                offset_y = 0.0;
                group = 1;
              }
            ];
          };
        };
      };

      # FIXME: Remove when https://github.com/NixOS/nixpkgs/issues/482152 is fixed
      systemd.user.services.wivrn.serviceConfig.ExecStart =
        let
          cfg = config.services.wivrn;
          configFormat = pkgs.formats.json { };
          configFile = configFormat.generate "config.json" cfg.config.json;
        in
        lib.mkForce "${cfg.package}/bin/wivrn-server -f ${configFile}";

      environment.systemPackages = [ pkgs.android-tools ];
    };

  flake.modules.homeManager.vr =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    lib.mkIf (osConfig.services.wivrn.enable or false) {
      # xrizer OpenVR paths - points to nix store (accessible via PRESSURE_VESSEL_FILESYSTEMS_RO)
      xdg.configFile."openvr/openvrpaths.vrpath" = {
        force = true;
        text = builtins.toJSON {
          version = 1;
          jsonid = "vrpathreg";
          external_drivers = null;
          config = [ "${config.xdg.dataHome}/Steam/config" ];
          log = [ "${config.xdg.dataHome}/Steam/logs" ];
          runtime = [ "${pkgs.xrizer}/lib/xrizer" ];
        };
      };

      # 32-bit OpenXR runtime manifest for 32-bit VR games (HL2VR, Portal VR)
      # The 32-bit OpenXR loader looks for active_runtime.i686.json before active_runtime.json
      xdg.configFile."openxr/1/active_runtime.i686.json" = {
        force = true;
        text = builtins.toJSON {
          file_format_version = "1.0.0";
          runtime = {
            name = "Monado";
            library_path = "${pkgs.wivrn}/lib32/wivrn/libopenxr_wivrn.so";
            MND_libmonado_path = "${pkgs.wivrn}/lib32/wivrn/libmonado_wivrn.so";
          };
        };
      };

      home.packages = [ pkgs.wayvr ];
    };
}
