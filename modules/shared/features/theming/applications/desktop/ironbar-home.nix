{
  config,
  lib,
  pkgs,
  themeContext ? null,
  signalPalette ? null, # Backward compatibility
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  # Use themeContext if available, otherwise fall back to signalPalette for backward compatibility
  theme = themeContext.theme or signalPalette;
in
{
  config = mkIf (cfg.enable && cfg.applications.ironbar.enable && theme != null) {
    programs.ironbar = {
      style =
        let
          colors = theme.colors or theme.semantic;
        in
        ''
          * {
            font-family: "Iosevka Nerd Font", "Font Awesome 6 Free", sans-serif;
            font-size: 14px;
            border: none;
          }

          #bar {
            background-color: ${colors."surface-base".hex};
            color: ${colors."text-primary".hex};
          }

          /* Workspace indicators */
          .workspaces button {
            padding: 0 10px;
            background-color: transparent;
            color: ${colors."text-secondary".hex};
            transition: all 0.2s ease-in-out;
          }

          .workspaces button:hover {
            background-color: ${colors."surface-emphasis".hex};
            color: ${colors."text-primary".hex};
          }

          .workspaces button.focused {
            background-color: ${colors."accent-focus".hex};
            color: ${colors."surface-base".hex};
            font-weight: bold;
          }

          .workspaces button.visible {
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-primary".hex};
          }

          /* Window title */
          .label {
            padding: 0 12px;
            margin: 0 2px;
            color: ${colors."text-secondary".hex};
            font-style: italic;
          }

          /* System info module */
          .sys-info {
            padding: 0 12px;
            margin: 0 2px;
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-primary".hex};
          }

          /* Brightness module */
          .brightness {
            padding: 0 12px;
            margin: 0 2px;
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."accent-warning".hex};
          }

          .brightness:hover {
            background-color: ${colors."surface-emphasis".hex};
          }

          /* Volume module */
          .volume {
            padding: 0 12px;
            margin: 0 2px;
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."accent-info".hex};
          }

          .volume:hover {
            background-color: ${colors."surface-emphasis".hex};
          }

          /* Clock module */
          .clock {
            padding: 0 12px;
            margin: 0 2px;
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-primary".hex};
            font-weight: 600;
          }

          .clock:hover {
            background-color: ${colors."surface-emphasis".hex};
            color: ${colors."accent-focus".hex};
          }

          /* System tray */
          .tray {
            padding: 0 8px;
            margin: 0 2px;
            background-color: transparent;
          }

          .tray menu {
            background-color: ${colors."surface-subtle".hex};
            border: 1px solid ${colors."divider-primary".hex};
            color: ${colors."text-primary".hex};
          }

          .tray menuitem {
            padding: 4px 8px;
          }

          .tray menuitem:hover {
            background-color: ${colors."surface-emphasis".hex};
          }

          /* Notifications module */
          .notifications {
            padding: 0 12px;
            margin: 0 2px;
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-primary".hex};
          }

          .notifications:hover {
            background-color: ${colors."surface-emphasis".hex};
          }

          .notifications.notification-count {
            color: ${colors."accent-danger".hex};
            font-weight: bold;
          }

          /* Custom modules */
          .custom {
            padding: 0 12px;
            margin: 0 2px;
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-primary".hex};
          }

          .custom:hover {
            background-color: ${colors."surface-emphasis".hex};
          }

          /* Scrollbar styling for modules with scroll */
          scrollbar {
            background-color: ${colors."surface-base".hex};
            min-width: 8px;
          }

          scrollbar slider {
            background-color: ${colors."divider-primary".hex};
            border-radius: 4px;
          }

          scrollbar slider:hover {
            background-color: ${colors."divider-secondary".hex};
          }

          /* Tooltip styling */
          tooltip {
            background-color: ${colors."surface-emphasis".hex};
            border: 1px solid ${colors."divider-primary".hex};
            border-radius: 4px;
            color: ${colors."text-primary".hex};
            padding: 4px 8px;
          }
        '';
    };
  };
}
