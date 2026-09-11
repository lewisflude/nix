# Niri window and layer rules.
#
# Every window rule lives in this one file on purpose. window-rules is a list
# option, so definitions from separate modules would be concatenated in module
# import order, and niri applies later rules over earlier ones — splitting them
# would make the result depend on filenames. Rules are ordered general first,
# specific last.
_: {
  flake.modules.homeManager.niri =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.niri.settings = {
        layer-rules = [
          {
            matches = [ { namespace = "^quickshell$"; } ];
            place-within-backdrop = true;
          }
        ];

        window-rules =
          let
            # Matches the corner radius DMS uses for its own surfaces, so
            # windows and shell UI agree. Previously set to 16 by the DMS
            # include and to 12 here; the include is gone, this is the value.
            r = 16.0;
            cornerRadius = {
              top-left = r;
              top-right = r;
              bottom-left = r;
              bottom-right = r;
            };

            floatingApps = map (id: { app-id = id; }) [
              "xdg-desktop-portal-gtk"
              "xdg-desktop-portal-gnome"
              "gcr-prompter"
              "nm-connection-editor"
              "blueman-manager"
              "^pavucontrol$"
              "^pwvucontrol$"
              "org.gnome.Calculator"
              "zenity"
            ];
          in
          [
            {
              geometry-corner-radius = cornerRadius;
              clip-to-geometry = true;
              # Draw the focus ring around the window rather than as a filled
              # rectangle behind it. Without this the ring shows through the
              # 0.95-opacity inactive windows set by the last rule below.
              # (tiled-state is not set here: prefer-no-csd in session.nix
              # already implies it.)
              draw-border-with-background = false;
            }

            {
              matches = [
                { app-id = "^org\\.quickshell$"; }
              ]
              ++ floatingApps
              ++ [
                {
                  app-id = "^firefox";
                  title = "^Picture-in-Picture$";
                }
                { title = "^Picture in picture$"; }
              ];
              open-floating = true;
            }

            {
              matches = [ { app-id = "^1password$"; } ];
              open-floating = true;
              block-out-from = "screencast";
            }

            {
              matches = [ { app-id = "^steam_app_"; } ];
              open-fullscreen = true;
              variable-refresh-rate = true;
            }

            {
              matches = [ { app-id = "^gamescope$"; } ];
              open-fullscreen = true;
              variable-refresh-rate = true;
            }

            {
              matches = [ { app-id = "^steam$"; } ];
              default-column-width.proportion = 0.65;
            }

            # Labwc nested compositor (used for Unity Editor)
            {
              matches = [ { app-id = "^labwc$"; } ];
              open-maximized = true;
            }

            {
              matches = [ { is-active = false; } ];
              opacity = 0.95;
            }
          ];
      };
    };
}
