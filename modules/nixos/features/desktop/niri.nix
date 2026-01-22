{
  config,
  lib,
  inputs,
  hostSystem,
  ...
}:
let
  cfg = config.host.features.desktop;
  inherit (inputs.niri.packages.${hostSystem}) niri-unstable;
in
{
  config = lib.mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = niri-unstable;
    };

    # Note: Process priority for niri is managed by ananicy-cpp automatically
    # Manual priority overrides can conflict with ananicy's dynamic management

    # NVIDIA application profile to fix high VRAM usage with niri
    # See: https://yalter.github.io/niri/Nvidia.html#high-vram-usage-fix
    # Only create this if NVIDIA is configured
    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" =
      lib.mkIf (config.hardware.nvidia.package != null) {
        text = ''
          {
              "rules": [
                  {
                      "pattern": {
                          "feature": "procname",
                          "matches": "niri"
                      },
                      "profile": "Limit Free Buffer Pool On Wayland Compositors"
                  }
              ],
              "profiles": [
                  {
                      "name": "Limit Free Buffer Pool On Wayland Compositors",
                      "settings": [
                          {
                              "key": "GLVidHeapReuseRatio",
                              "value": 0
                          }
                      ]
                  }
              ]
          }
        '';
        mode = "0644";
      };
  };
}
