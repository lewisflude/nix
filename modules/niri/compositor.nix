# Niri — the compositor package, overlay, and system-level session plumbing.
#
# Split out from the rest of modules/niri/ because this is the only part that
# lands in the NixOS scope. Everything else in this directory configures the
# user session through programs.niri.settings.
{ inputs, ... }:
{
  overlays.niri =
    final: prev: if prev.stdenv.hostPlatform.isLinux then inputs.niri.overlays.niri final prev else { };

  flake.modules.nixos.niri =
    { lib, config, ... }:
    {
      programs.niri = {
        enable = true;
        package = inputs.niri.packages.${config.nixpkgs.hostPlatform.system}.niri-unstable;
      };

      # UWSM session management for niri
      programs.uwsm = {
        enable = true;
        waylandCompositors.niri = {
          prettyName = "Niri";
          comment = "Niri compositor managed by UWSM";
          binPath = lib.getExe config.programs.niri.package;
        };
      };

      # niri-flake targets WantedBy=niri.service, but UWSM uses
      # wayland-wm@niri-session.service — fix to target graphical-session.target
      systemd.user.services.niri-flake-polkit.wantedBy = lib.mkForce [
        "graphical-session.target"
      ];

      # NVIDIA application profile to fix high VRAM usage with niri
      # See: https://niri-wm.github.io/niri/Nvidia.html#high-vram-usage-fix
      environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" =
        lib.mkIf config.hardware.nvidia.enabled {
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
