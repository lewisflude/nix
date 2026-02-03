# Niri Compositor Configuration
# Niri Wayland compositor with NVIDIA optimizations
{ config, inputs, ... }:
{
  flake.modules.nixos.niri =
    { lib, config, ... }:
    {
      programs.niri = {
        enable = true;
        package = inputs.niri.packages.${config.nixpkgs.hostPlatform.system}.niri-unstable;
      };

      # NVIDIA application profile to fix high VRAM usage with niri
      # See: https://yalter.github.io/niri/Nvidia.html#high-vram-usage-fix
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
