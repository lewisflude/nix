# VR Module - WiVRn + xrizer for Quest headsets
# References:
# - https://lvra.gitlab.io/docs/distros/nixos/
_: {
  flake.modules.nixos.vr =
    { pkgs, ... }:
    {
      # Steam VR integration (per LVRA NixOS guide)
      # Sets OpenXR runtime import for pressure-vessel/Proton.
      # Non-VR games that break with VR detection need per-game launch options:
      #   PROTON_VR_RUNTIME="" %command%
      programs.steam.extraPackages = [ pkgs.xrizer ];
      environment.sessionVariables = {
        PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = "1";
      };

      services.wivrn = {
        enable = true;
        openFirewall = true;
        autoStart = true;

        monadoEnvironment = {
          U_PACING_COMP_MIN_TIME_MS = "5";
          IPC_EXIT_ON_DISCONNECT = "1";
        };

        config = {
          enable = true;
          json = {
            application = [ pkgs.wayvr ];
          };
        };
      };

      # WiVRn strips the application path to just the basename when creating
      # transient systemd units, so wayvr must be in the service's ExecSearchPath
      systemd.user.services.wivrn = {
        path = [
          pkgs.wayvr
          "/run/current-system/sw"
          "/etc/profiles/per-user/lewisflude"
        ];
        environment.NIXOS_OZONE_WL = "1";
      };

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
      home.packages = [ pkgs.android-tools ];
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
    };
}
