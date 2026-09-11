# Niri tiling layout — column sizing, centring, tabs, and the motion around it.
#
# ── Who owns the layout section ─────────────────────────────────────────────
# niri assembles its config from ~/.config/niri/config.kdl, which is a stub of
# positional includes:
#
#     hm.kdl  →  dms/alttab.kdl  →  dms/colors.kdl  →  dms/wpblur.kdl
#
# Includes override settings defined *before* them, and hm.kdl (generated from
# this file) is first. DMS used to emit a dms/layout.kdl in that chain too,
# which silently overrode gaps, focus-ring width, and the geometry window rule
# in rules.nix. That file is no longer included — see the filesToInclude list
# in modules/dms.nix — so every layout value is decided here, and the values
# DMS used to supply are restated below rather than inherited.
#
# DMS still owns colours (dms/colors.kdl), the Alt-Tab switcher (dms/alttab.kdl)
# and the wallpaper backdrop rule (dms/wpblur.kdl). Those are theme-derived and
# are deliberately not duplicated in Nix.
_: {
  flake.modules.homeManager.niri =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.niri.settings = {
        layout = {
          # Was 4, set by DMS. 8 reads better against the 16px corner radius in
          # rules.nix without giving up usable width on a 3440px output.
          gaps = 8;

          # Centre the focused column only when it cannot share the screen with
          # the column you came from. "always" would re-centre on every focus
          # change, and combined with focus-follows-mouse max-scroll-amount
          # "0%" (session.nix) that disables follow-mouse between columns
          # entirely, because every cross-column focus would scroll the view.
          center-focused-column = "on-overflow";

          # A lone column sits centred rather than pinned to the left edge.
          always-center-single-column = true;

          # Without this niri sends a (0, H) initial configure and lets the
          # client pick its own width, which varies per toolkit. Half of a
          # 3440px output is a workable default for a main window.
          default-column-width.proportion = 1.0 / 2.0;

          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
            { proportion = 1.0; }
          ];

          preset-window-heights = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
            { proportion = 1.0; }
          ];

          # Matches the 2px ring DMS used to set. The ring is the only window
          # decoration in use — borders stay off (niri-flake's default).
          focus-ring.width = 2;

          tab-indicator = {
            # A single-window column is not visibly a tab stack, so the
            # indicator is noise until a column actually holds tabs.
            hide-when-single-tab = true;
            # Draw the indicator inside the column's own width. By default it
            # is drawn outside, where it overlays the neighbouring column or
            # falls off the edge of the screen.
            place-within-column = true;
          };
        };

        overview.zoom = 0.5;

        gestures = {
          hot-corners.enable = true;
          dnd-edge-view-scroll = {
            delay-ms = 200;
            trigger-width = 48;
            max-speed = 1000;
          };
          dnd-edge-workspace-switch = {
            delay-ms = 200;
            trigger-height = 48;
            max-speed = 1000;
          };
        };

        animations =
          let
            snappy.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 1000;
              epsilon = 0.0001;
            };
            quick.kind.easing = {
              duration-ms = 150;
              curve = "ease-out-quad";
            };
          in
          {
            workspace-switch = snappy;
            window-movement = snappy;
            window-open = snappy;
            window-resize = snappy;
            horizontal-view-movement = snappy;
            window-close = quick;
            screenshot-ui-open = quick;
            overview-open-close = quick;
          };
      };
    };
}
