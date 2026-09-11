# Niri user session — package selection, cursor, Xwayland, input devices.
#
# The parts of the session that are not layout, binds, or window rules. Those
# live in sibling files; all four contribute to flake.modules.homeManager.niri.
{ inputs, ... }:
{
  flake.modules.homeManager.niri =
    {
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.wlr-randr
        pkgs.argyllcms
        pkgs.wl-gammactl
      ];

      home.pointerCursor = {
        enable = true;
        name = "phinger-cursors-light";
        package = pkgs.phinger-cursors;
        size = 32;
        gtk.enable = true;
        x11.enable = true;
      };

      programs.hyprcursor-phinger.enable = true;

      programs.niri = {
        # Use the niri-flake package built against its pinned nixpkgs (see the
        # nixpkgs-niri note in flake.nix) rather than the overlay against the
        # system nixpkgs, which currently throws on the removed libdisplay-info_0_2.
        package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;

        settings = {
          # Ask clients to omit their own decorations. Niri then knows the
          # window geometry exactly, which is what makes the focus ring and the
          # corner radius in rules.nix line up with the actual window edges.
          # It also implies tiled-state, so tiled clients square their corners.
          prefer-no-csd = true;
          hotkey-overlay.skip-at-startup = true;

          screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

          xwayland-satellite = {
            enable = true;
            path = lib.getExe pkgs.xwayland-satellite-unstable;
          };

          debug = lib.mkIf (osConfig.host.hardware.renderDevice or null != null) {
            render-drm-device = osConfig.host.hardware.renderDevice;
          };

          environment = {
            MOZ_ENABLE_WAYLAND = "1";
          };

          cursor = {
            hide-when-typing = true;
            hide-after-inactive-ms = 5000;
          };

          input = {
            keyboard = {
              xkb.layout = "us";
              repeat-delay = 600;
              repeat-rate = 25;
            };

            # max-scroll-amount "0%" is load-bearing for the centring modes in
            # layout.nix: it stops focus-follows-mouse from firing whenever the
            # pointer crosses into a column that is only partly on screen, which
            # would otherwise scroll the view out from under the pointer.
            focus-follows-mouse = {
              enable = true;
              max-scroll-amount = "0%";
            };

            warp-mouse-to-focus = {
              enable = true;
              mode = "center-xy";
            };

            workspace-auto-back-and-forth = true;

            mouse = {
              natural-scroll = true;
              accel-profile = "flat";
            };
          };
        };
      };
    };
}
