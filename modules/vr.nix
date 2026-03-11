# VR Module - WiVRn + xrizer for Quest headsets
# References:
# - https://lvra.gitlab.io/docs/distros/nixos/
# - https://wiki.nixos.org/wiki/VR
#
# NOTE: VR also requires Steam integration configured in gaming.nix
# (PRESSURE_VESSEL env vars, xrizer in extraPkgs)
_: {
  flake.modules.nixos.vr =
    { pkgs, ... }:
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
            encoder =
              let
                eye = offset_x: group: {
                  encoder = "nvenc";
                  codec = "av1";
                  width = 0.5;
                  height = 1.0;
                  inherit offset_x group;
                  offset_y = 0.0;
                };
              in
              [
                (eye 0.0 0)
                (eye 0.5 1)
              ];
          };
        };
      };

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

      home.packages = [ pkgs.wayvr ];
    };
}
