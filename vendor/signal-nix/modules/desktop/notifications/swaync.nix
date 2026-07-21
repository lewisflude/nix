{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: services.swaync (via xdg.configFile)
# UPSTREAM SCHEMA: https://github.com/ErikReider/SwayNotificationCenter
# SCHEMA VERSION: 0.10.1+
# LAST VALIDATED: 2026-01-21
# NOTES: SwayNC uses CSS for styling. Home Manager doesn't have a structured module,
#        so we use xdg.configFile for the style.css file. Signal ONLY sets colors.
#        Users configure fonts, spacing, animations, etc. in their own config.
#        For complete styling (colors + padding + spacing + animations), use
#        signal-notifications: https://github.com/lewisflude/signal-notifications
#        Fixed: Changed activation check to services.swaync.enable (was checking programs)
#        Fixed: Updated CSS selectors to match upstream (.control-center, .notification-row)
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Helper functions for semantic color access
  c = cat: name: (semantic.resolve cat name themeMode).hex;
  cUI = name: (semantic.ui name themeMode).hex;
  cText = name: (semantic.text name themeMode).hex;
  cCore = name: (semantic.core name themeMode).hex;
  cStatus = name: (semantic.status name themeMode).hex;

  # Generate SwayNC CSS using semantic bridge - COLORS ONLY
  swayNcCss = ''
    /**
     * Signal theme for Sway Notification Center
     * This file ONLY contains color overrides.
     * Configure fonts, spacing, animations, etc. in your own style.css
     */

    /* =============================================================================
       COLOR DEFINITIONS - Using Semantic Bridge
       ============================================================================= */

    @define-color text-primary ${cText "primary"};
    @define-color text-secondary ${cText "secondary"};
    @define-color text-tertiary ${cText "disabled"};

    @define-color surface-base ${cUI "panel-background"};
    @define-color surface-raised ${cUI "element-hover"};
    @define-color surface-emphasis ${cUI "element-active"};

    @define-color divider-primary ${cUI "panel-border"};
    @define-color divider-secondary ${cUI "element-active"};

    @define-color accent-focus ${cCore "focus"};
    @define-color accent-success ${cStatus "success"};
    @define-color accent-warning ${cStatus "warning"};
    @define-color accent-danger ${cStatus "error"};
    @define-color accent-info ${cStatus "info"};

    /* =============================================================================
       CONTROL CENTER WINDOW
       ============================================================================= */

    .control-center {
      background-color: @surface-base;
      color: @text-primary;
    }

    .control-center-list-placeholder {
      color: @text-tertiary;
    }

    .control-center-list {
      background-color: transparent;
    }

    /* =============================================================================
       NOTIFICATIONS
       ============================================================================= */

    .notification-row {
      background: none;
    }

    .notification-row:focus,
    .notification-row:hover {
      background-color: @surface-hover;
    }

    .notification {
      background-color: @surface-raised;
      color: @text-primary;
      border: 1px solid @divider-primary;
    }

    /* Notification close button */
    .close-button {
      background-color: transparent;
      color: @text-secondary;
    }

    .close-button:hover {
      background-color: @accent-danger;
      color: @surface-base;
    }

    /* Notification content */
    .notification-default-action {
      color: @text-primary;
    }

    .notification-default-action:hover {
      background-color: @surface-emphasis;
    }

    /* Notification title and body */
    .summary {
      color: @text-primary;
    }

    .body {
      color: @text-secondary;
    }

    .time {
      color: @text-tertiary;
    }

    /* Notification actions */
    .notification-action button {
      background-color: @surface-base;
      color: @accent-focus;
      border: 1px solid @accent-focus;
    }

    .notification-action button:hover {
      background-color: @accent-focus;
      color: @surface-base;
    }

    /* =============================================================================
       URGENCY LEVELS
       ============================================================================= */

    /* Low urgency */
    .notification.low {
      border-left: 4px solid @accent-info;
    }

    /* Normal urgency */
    .notification.normal {
      border-left: 4px solid @accent-focus;
    }

    /* Critical urgency */
    .notification.critical {
      background-color: @accent-danger;
      color: @surface-base;
      border-left: 4px solid @accent-danger;
    }

    .notification.critical .title,
    .notification.critical .body,
    .notification.critical .time {
      color: @surface-base;
    }

    .notification.critical .close-button {
      color: @surface-base;
    }

    .notification.critical .close-button:hover {
      background-color: @divider-secondary;
    }

    /* =============================================================================
       WIDGETS
       ============================================================================= */

    /* Control center widgets */
    .widget {
      background-color: @surface-raised;
      color: @text-primary;
      border: 1px solid @divider-primary;
    }

    .widget button {
      background-color: @surface-base;
      color: @text-primary;
    }

    .widget button:hover {
      background-color: @surface-emphasis;
    }

    .widget button.active {
      background-color: @accent-focus;
      color: @surface-base;
    }

    /* Volume/brightness sliders */
    .widget scale trough {
      background-color: @surface-base;
    }

    .widget scale highlight {
      background-color: @accent-focus;
    }

    /* Do Not Disturb button */
    .widget-dnd button.active {
      background-color: @accent-warning;
      color: @surface-base;
    }

    /* Clear all button */
    .control-center-clear-all {
      background-color: transparent;
      color: @accent-danger;
      border: 1px solid @accent-danger;
    }

    .control-center-clear-all:hover {
      background-color: @accent-danger;
      color: @surface-base;
    }

    /* =============================================================================
       FLOATING NOTIFICATIONS (popup notifications)
       ============================================================================= */

    .floating-notifications {
      background: transparent;
    }

    /* Blank window (behind control center) */
    .blank-window {
      background: transparent;
    }

    /* =============================================================================
       MISC ELEMENTS
       ============================================================================= */

    /* Progress bars */
    progressbar {
      background-color: @surface-base;
    }

    progressbar progress {
      background-color: @accent-focus;
    }

    /* Images in notifications */
    .image {
      border-radius: 8px;
    }

    .body-image {
      background-color: transparent;
    }

    /* Inline replies */
    .inline-reply-entry {
      background-color: @surface-base;
      color: @text-primary;
      caret-color: @text-primary;
      border: 1px solid @divider-primary;
    }

    .inline-reply-entry:focus {
      border-color: @accent-focus;
    }

    .inline-reply-button {
      background-color: @surface-base;
      color: @accent-focus;
      border: 1px solid @accent-focus;
    }

    .inline-reply-button:hover {
      background-color: @accent-focus;
      color: @surface-base;
    }

    .inline-reply-button:disabled {
      color: @text-tertiary;
      border-color: @divider-primary;
    }
  '';

  # Check if swaync should be themed
  # NOTE: SwayNC is a service, not a program, so we check services.swaync.enable
  shouldTheme =
    cfg.desktop.notifications.swaync.enable
    || (cfg.autoEnable && (config.services.swaync.enable or false));

  # Platform guard - SwayNC is Linux-only (Wayland notification center)
  platformOk = signalLib.platform.guard pkgs "swaync";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    # SwayNC styling via CSS
    xdg.configFile."swaync/style.css".text = swayNcCss;
  };
}
