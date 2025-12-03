{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  inherit (themeContext) theme;
in
{
  config = mkIf (cfg.enable && cfg.applications.ironbar.enable && theme != null) {
    programs.ironbar = {
      style =
        let
          inherit (theme) colors;
          radius = "12px";
        in
        ''
          /* Global Reset */
          * {
            font-family: "JetBrainsMono Nerd Font", "Iosevka Nerd Font", sans-serif;
            font-size: 14px;
            font-weight: 600;
            border: none;
            border-radius: 0;
            min-height: 0;
            box-shadow: none;
            text-shadow: none;
          }

          /*
             CRITICAL: Window Transparency
             We target every possible container to ensure no black background
          */
          window#ironbar,
          #bar,
          .background {
            background-color: rgba(0,0,0,0);
            background-image: none;
          }

          /*
             --- Module Pills ---
             We apply the pill styling to the top-level module containers.
             This ensures the rounded shape and background applies to the "Island".
          */
          .workspaces,
          .label,
          .clock,
          .sys-info,
          .brightness,
          .volume,
          .tray,
          .notifications {
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-primary".hex};

            /* The Pill Shape */
            border-radius: ${radius};
            border: 1px solid ${colors."divider-primary".hex};

            /* Spacing around the pill (Floating effect) */
            margin-top: 4px;
            margin-bottom: 4px;
            margin-left: 4px;
            margin-right: 4px;

            /* Internal Padding (Space inside the pill) */
            padding-top: 0px;
            padding-bottom: 0px;
            padding-left: 16px;
            padding-right: 16px;
          }

          /* --- Specific Module Adjustments --- */

          /* Workspaces: Needs tighter padding because buttons have their own padding */
          .workspaces {
            padding: 0 8px;
          }

          .workspaces button {
            background-color: transparent;
            color: ${colors."text-secondary".hex};
            padding: 4px 12px;
            margin: 4px 2px; /* Add vertical margin to float inside container */
            border-radius: 8px;
          }

          .workspaces button:hover {
             background-color: ${colors."surface-emphasis".hex};
             color: ${colors."text-primary".hex};
          }

          .workspaces button.focused {
            background-color: ${colors."accent-focus".hex};
            color: ${colors."surface-base".hex};
            min-width: 32px;
          }

          .workspaces button.visible {
             background-color: ${colors."surface-subtle".hex};
          }

          /* Clock */
          .clock {
             color: ${colors."accent-primary".hex};
             font-weight: 800;
             padding: 0 24px; /* Wider padding for the anchor */
          }

          .clock:hover {
             background-color: ${colors."surface-emphasis".hex};
          }

          /* SysInfo - The "Microchip" Module
             Issue: It creates multiple children. We want the CONTAINER to be the pill.
             We must ensure children are invisible layout-wise.
          */
          .sys-info {
             color: ${colors."accent-info".hex};
             /* Ensure flex/box layout doesn't break */
          }

          .sys-info button, .sys-info label {
             background: none;
             border: none;
             padding: 0 4px; /* Space between CPU and RAM text */
             margin: 0;
             box-shadow: none;
          }

          /* Brightness & Volume */
          .brightness { color: ${colors."accent-warning".hex}; }
          .volume { color: ${colors."accent-primary".hex}; }

          /* Tray */
          .tray {
            padding: 0 12px;
          }

          /* Notifications */
          .notifications {
             /* Symmetrical padding */
             padding-left: 16px;
             padding-right: 16px;

             /* Force right margin for the bar end */
             margin-right: 12px !important;
          }

          .notifications.notification-count {
             color: ${colors."accent-danger".hex};
          }

          /* Label (Title) */
          .label {
             color: ${colors."text-secondary".hex};
             font-style: italic;
             margin-right: 12px; /* Gap between context and rest */
          }

          /* Tooltips */
          tooltip {
            background-color: ${colors."surface-base".hex};
            border: 1px solid ${colors."divider-primary".hex};
            border-radius: ${radius};
            padding: 8px 12px;
          }

          /* Popup Menu */
          popup {
             background-color: ${colors."surface-base".hex};
             border: 1px solid ${colors."divider-primary".hex};
             border-radius: ${radius};
             padding: 10px;
             margin-top: 8px;
          }
        '';
    };
  };
}
