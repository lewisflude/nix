# Jupiter-specific niri output and display configuration
# Monitor layout, ICC profile, and gamma for the AW3423DWF + virtual streaming display
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

          # QD-OLED VRR flicker is worst on the desktop: dark UI at low,
          # erratically varying framerates. It is least noticeable in games,
          # which are also the only place VRR pays for itself. "on-demand"
          # holds a fixed 164.9 Hz until a window carrying the
          # `variable-refresh-rate` rule (steam_app_*, gamescope — see
          # modules/niri.nix) appears on this output.
          #
          # Requires that nvidia-modeset.conceal_vrr_caps stays out of
          # boot.kernelParams; with it set the driver reports vrr_capable=0
          # and niri silently ignores this.
          variable-refresh-rate = "on-demand";
        };

        # Virtual 16:9 streaming display — off by default, enabled by sunshine's
        # systemd preStart at service start, then toggled per-stream by prep-cmd.
        outputs."DP-3" = {
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

        # Hardware HDMI dummy plug. Required so NVIDIA's proprietary driver
        # brings up its KMS modeset pipeline — without a real DDC EDID on at
        # least one connector, sunshine fails with "Unable to find display or
        # encoder". Kept disabled here so niri/DMS don't render to it; only the
        # plug's electrical presence at the DRM layer matters. The actual
        # streaming surface is DP-3 above.
        outputs."HDMI-A-1".enable = false;

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
