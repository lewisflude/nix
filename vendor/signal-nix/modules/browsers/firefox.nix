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
# CONFIGURATION METHOD: raw-css (Tier 5)
# HOME-MANAGER MODULE: programs.firefox.profiles.<name>.userChrome
# UPSTREAM SCHEMA: https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/theme
# SCHEMA VERSION: 122.0
# LAST VALIDATED: 2026-01-17
# NOTES: Firefox uses userChrome.css for UI theming. This is advanced and may
#        break with Firefox updates. Home-Manager supports this via profile configs.
let
  inherit (lib) mkIf mkDefault;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    surface-raised = semantic.ui "element-hover" themeMode;
    surface-hover = semantic.ui "element-active" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-dim = semantic.text "tertiary" themeMode;
    divider = semantic.ui "panel-border" themeMode;
    accent = semantic.core "focus" themeMode;
    success = semantic.status "success" themeMode;
    warning = semantic.status "warning" themeMode;
    danger = semantic.status "error" themeMode;
  };

  # Generate userChrome.css content
  userChromeCSS = ''
    /* Signal Firefox Theme */
    /* WARNING: This may break with Firefox updates */

    :root {
      --signal-bg: ${colors.surface-base.hex};
      --signal-bg-alt: ${colors.surface-raised.hex};
      --signal-bg-hover: ${colors.surface-hover.hex};
      --signal-fg: ${colors.text-primary.hex};
      --signal-fg-alt: ${colors.text-secondary.hex};
      --signal-fg-dim: ${colors.text-dim.hex};
      --signal-border: ${colors.divider.hex};
      --signal-accent: ${colors.accent.hex};
      --signal-success: ${colors.success.hex};
      --signal-warning: ${colors.warning.hex};
      --signal-danger: ${colors.danger.hex};
    }

    /* Toolbar */
    #navigator-toolbox {
      background-color: var(--signal-bg) !important;
      border-color: var(--signal-border) !important;
    }

    /* Tabs */
    .tabbrowser-tab {
      color: var(--signal-fg-alt) !important;
    }

    .tabbrowser-tab[selected] {
      color: var(--signal-fg) !important;
      background-color: var(--signal-bg-alt) !important;
    }

    .tab-background {
      background-color: var(--signal-bg) !important;
    }

    .tab-background[selected] {
      background-color: var(--signal-bg-alt) !important;
    }

    /* URL bar */
    #urlbar, #searchbar {
      background-color: var(--signal-bg-alt) !important;
      color: var(--signal-fg) !important;
      border-color: var(--signal-border) !important;
    }

    #urlbar:focus, #searchbar:focus {
      border-color: var(--signal-accent) !important;
    }

    /* Sidebar */
    #sidebar-box {
      background-color: var(--signal-bg) !important;
      color: var(--signal-fg) !important;
    }

    /* Context menus */
    menupopup, popup {
      background-color: var(--signal-bg-alt) !important;
      color: var(--signal-fg) !important;
      border-color: var(--signal-border) !important;
    }

    menuitem:hover, menu:hover {
      background-color: var(--signal-bg-hover) !important;
    }
  '';

  # Check if firefox should be themed
  shouldTheme = signalLib.shouldThemeApp "firefox" [
    "browsers"
    "firefox"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme && (config.programs.firefox.enable or false)) {
    # Apply userChrome.css to all Firefox profiles
    programs.firefox.profiles = lib.mkIf (config.programs.firefox ? profiles) (
      lib.mapAttrs (name: profile: {
        userChrome = mkDefault userChromeCSS;

        # Also set some about:config preferences for better theming
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # Enable userChrome.css
          "browser.theme.content-theme" = if cfg.mode == "dark" then 0 else 1;
          "browser.theme.toolbar-theme" = if cfg.mode == "dark" then 0 else 1;
        };
      }) config.programs.firefox.profiles
    );
  };
}
