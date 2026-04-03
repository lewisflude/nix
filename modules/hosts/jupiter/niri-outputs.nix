# Jupiter-specific niri output and display configuration
# Monitor layout, ICC profile, and gamma for the AW3423DWF + Sunshine HDMI
_: {
  flake.modules.homeManager.niriOutputsJupiter =
    { config, pkgs, ... }:
    {
      programs.niri.settings = {
        outputs."DP-1" = {
          mode = {
            width = 3440;
            height = 1440;
            refresh = 164.900;
          };
          position = {
            x = 0;
            y = 0;
          };
          focus-at-startup = true;
        };

        # Sunshine streaming output — disabled by default, toggled via sunshine prep-cmd
        outputs."HDMI-A-1" = {
          enable = false;
          mode = {
            width = 1920;
            height = 1080;
            refresh = 60.0;
          };
          position = {
            x = 3440;
            y = 0;
          };
        };

        spawn-at-startup = [
          {
            command = [
              "${pkgs.argyllcms}/bin/dispwin"
              "-d"
              "1"
              "${config.home.homeDirectory}/.local/share/icc/aw3423dwf.icc"
            ];
          }
          {
            command = [
              "${pkgs.wl-gammactl}/bin/wl-gammactl"
              "--gamma"
              "1.0"
              "--brightness"
              "1.0"
            ];
          }
        ];
      };
    };
}
