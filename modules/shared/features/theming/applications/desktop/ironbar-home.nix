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
          # Common radii for consistent design
          radius = "12px";
          innerRadius = "8px";
        in
        ''
          * {
            font-family: "JetBrainsMono Nerd Font", "Iosevka Nerd Font", sans-serif;
            font-size: 14px;
            font-weight: 600;
            border: none;
            border-radius: ${radius};
            transition: background-color 0.2s ease;
          }

          /* Main transparent bar */
          window#ironbar {
            background-color: transparent;
          }

          #bar {
            background-color: transparent;
            color: ${colors."text-primary".hex};
          }

          /* --- Module Groups (Islands) --- */
          /* We simulate islands by giving modules backgrounds and spacing */
          /* 4px spacing system */

          .widget, .workspaces, .label, .clock, .sys-info, .brightness, .volume, .tray, .notifications {
             margin-top: 4px;    /* 1x4 */
             margin-bottom: 4px; /* 1x4 */
          }

          .widget {
            background-color: ${colors."surface-subtle".hex};
            margin-left: 4px;  /* 1x4 */
            margin-right: 4px; /* 1x4 */
            padding: 0;
            border: 1px solid ${colors."divider-primary".hex};
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2);
          }

          /* --- Left Group: Workspaces & Title --- */
          .workspaces {
            background-color: ${colors."surface-subtle".hex};
            padding: 4px 8px; /* 1x4 vertical, 2x4 horizontal */
            margin-left: 4px;
            margin-right: 4px;
            border-radius: ${radius};
            border: 1px solid ${colors."divider-primary".hex};
          }

          .workspaces button {
            background-color: transparent;
            color: ${colors."text-secondary".hex};
            padding: 4px 12px; /* 1x4 vertical, 3x4 horizontal */
            margin: 0 4px;     /* 1x4 */
            border-radius: ${innerRadius};
            box-shadow: none;
          }

          .workspaces button:hover {
            background-color: ${colors."surface-emphasis".hex};
            color: ${colors."text-primary".hex};
          }

          .workspaces button.focused {
            background-color: ${colors."accent-focus".hex};
            color: ${colors."surface-base".hex};
            min-width: 32px; /* 8x4 - Consistent width for active */
          }

          .workspaces button.visible {
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-primary".hex};
          }

          .label {
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-secondary".hex};
            padding: 0 16px;   /* 4x4 */
            margin-right: 8px; /* 2x4 - Extra space after context group */
            margin-left: 4px;  /* 1x4 */
            opacity: 0.8;
            border-radius: ${radius};
            border: 1px solid ${colors."divider-primary".hex};
          }

          /* --- Center Group: Clock --- */
          .clock {
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."accent-primary".hex};
            padding: 0 24px;
            font-size: 15px;
            font-weight: 800;
            margin-left: 4px;
            margin-right: 4px;
            border-radius: ${radius};
            border: 1px solid ${colors."divider-primary".hex};
          }

          .clock:hover {
            background-color: ${colors."surface-emphasis".hex};
          }

          /* --- Right Group: System --- */
          /* Unified look for system modules */
          .sys-info, .brightness, .volume, .tray, .notifications {
            background-color: ${colors."surface-subtle".hex};
            padding: 0 16px;   /* 4x4 */
            color: ${colors."text-primary".hex};
            margin-left: 4px;  /* 1x4 */
            margin-right: 4px; /* 1x4 */
            border-radius: ${radius};
            border: 1px solid ${colors."divider-primary".hex};
          }

          .sys-info {
            color: ${colors."accent-info".hex};
          }

          .brightness {
             color: ${colors."accent-warning".hex};
          }

          .volume {
            color: ${colors."accent-primary".hex};
          }

          .notifications {
             padding-right: 20px; /* 5x4 - End cap padding */
          }

          .notifications.notification-count {
            color: ${colors."accent-danger".hex};
            animation: pulse 2s infinite;
          }

          .tray {
            padding: 0 12px;
          }

          /* --- Tooltips & Menus --- */
          tooltip {
            background-color: ${colors."surface-base".hex};
            border: 1px solid ${colors."divider-primary".hex};
            border-radius: ${radius};
            padding: 8px 12px;
          }

          popup {
             background-color: ${colors."surface-base".hex};
             border: 1px solid ${colors."divider-primary".hex};
             border-radius: ${radius};
             padding: 10px;
          }

          /* --- Animation --- */
          @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.7; }
            100% { opacity: 1; }
          }
        '';
    };
  };
}
