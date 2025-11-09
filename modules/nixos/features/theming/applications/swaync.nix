{
  config,
  lib,
  pkgs,
  signalPalette ? null,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.theming.signal;
  theme = signalPalette;
  colors = theme.colors;

  # Determine libadwaita color scheme from theme mode
  # libadwaita uses "prefer-dark", "prefer-light", or "default"
  adwColorScheme =
    if cfg.mode == "dark" then
      "prefer-dark"
    else if cfg.mode == "light" then
      "prefer-light"
    else
      "prefer-dark"; # Default to dark for "auto" mode

  # Generate SwayNC CSS theme
  generateSwayncCss = ''
    /* Signal Theme - SwayNC Notification Center */

    /* Control Center (main panel) */
    .control-center {
      background: ${theme.withAlpha colors."surface-base" 0.95};
      border: 1px solid ${colors."divider-primary".hex};
      border-radius: 12px;
      box-shadow: 0 4px 16px ${theme.withAlpha colors."surface-base" 0.3};
    }

    /* Notification list */
    .notification-row {
      background: transparent;
      border-radius: 8px;
      margin: 4px;
    }

    .notification-row:focus,
    .notification-row:hover {
      background: ${colors."surface-subtle".hex};
    }

    /* Individual notifications */
    .notification {
      background: ${colors."surface-subtle".hex};
      border: 1px solid ${colors."divider-primary".hex};
      border-radius: 8px;
      color: ${colors."text-primary".hex};
      padding: 12px;
      margin: 4px;
    }

    .notification.critical {
      background: ${theme.withAlpha colors."accent-danger" 0.15};
      border-color: ${colors."accent-danger".hex};
    }

    .notification.low {
      background: ${colors."surface-subtle".hex};
      border-color: ${colors."divider-secondary".hex};
      opacity: 0.8;
    }

    /* Notification content */
    .notification-content {
      color: ${colors."text-primary".hex};
    }

    .notification-summary {
      color: ${colors."text-primary".hex};
      font-weight: 600;
    }

    .notification-body {
      color: ${colors."text-secondary".hex};
    }

    /* Notification icons */
    .notification-icon {
      color: ${colors."text-primary".hex};
    }

    .notification-icon.critical {
      color: ${colors."accent-danger".hex};
    }

    /* Close button */
    .notification-close-button {
      color: ${colors."text-tertiary".hex};
      background: transparent;
      border-radius: 4px;
    }

    .notification-close-button:hover {
      background: ${colors."surface-emphasis".hex};
      color: ${colors."text-primary".hex};
    }

    /* Action buttons */
    .notification-action {
      background: ${colors."surface-emphasis".hex};
      color: ${colors."text-primary".hex};
      border: 1px solid ${colors."divider-primary".hex};
      border-radius: 6px;
      padding: 6px 12px;
    }

    .notification-action:hover {
      background: ${colors."accent-primary".hex};
      color: ${colors."surface-base".hex};
      border-color: ${colors."accent-primary".hex};
    }

    /* Title widget */
    .notification-title {
      color: ${colors."text-primary".hex};
      font-weight: 700;
      font-size: 18px;
    }

    /* DND widget */
    .dnd-button {
      background: ${colors."surface-subtle".hex};
      color: ${colors."text-primary".hex};
      border: 1px solid ${colors."divider-primary".hex};
      border-radius: 6px;
    }

    .dnd-button:checked {
      background: ${colors."accent-primary".hex};
      color: ${colors."surface-base".hex};
      border-color: ${colors."accent-primary".hex};
    }

    /* Clear all button */
    .clear-all-button {
      background: ${colors."surface-emphasis".hex};
      color: ${colors."text-primary".hex};
      border: 1px solid ${colors."divider-primary".hex};
      border-radius: 6px;
    }

    .clear-all-button:hover {
      background: ${colors."accent-warning".hex};
      color: ${colors."surface-base".hex};
      border-color: ${colors."accent-warning".hex};
    }

    /* Empty state */
    .empty-notifications {
      color: ${colors."text-tertiary".hex};
    }

    /* Scrollbar */
    scrollbar {
      background: ${colors."surface-base".hex};
    }

    scrollbar slider {
      background: ${colors."divider-primary".hex};
      border-radius: 4px;
    }

    scrollbar slider:hover {
      background: ${colors."divider-secondary".hex};
    }
  '';
in
{
  config = mkIf (cfg.enable && cfg.applications.swaync.enable && theme != null) (mkMerge [
    {
      # Apply theme CSS to SwayNC via home-manager
      home-manager.users.${config.host.username} = {
        services.swaync = {
          style = generateSwayncCss;
        };
      };
    }
    {
      # Configure systemd user service for swaync to set libadwaita color scheme
      # This fixes the warning: "Using GtkSettings:gtk-application-prefer-dark-theme
      # with libadwaita is unsupported. Please use AdwStyleManager:color-scheme instead."
      systemd.user.services.swaync = {
        serviceConfig = {
          Environment = [
            "ADW_COLOR_SCHEME=${adwColorScheme}"
          ];
        };
      };
    }
  ]);
}
