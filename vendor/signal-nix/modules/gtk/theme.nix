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
# HOME-MANAGER MODULE: gtk.gtk3.extraCss / gtk.gtk4.extraCss
# UPSTREAM SCHEMA: https://docs.gtk.org/gtk3/css-properties.html
# SCHEMA VERSION: GTK 3.24 / GTK 4.12
# LAST VALIDATED: 2026-01-19
# NOTES: GTK theming requires CSS overrides using @define-color directives for GTK3
#        and CSS custom properties (--variable-name) for GTK4.
#        Home-Manager provides extraCss for custom CSS. No structured GTK color
#        options exist. Uses Adwaita base theme with color overrides.
#
#        This module follows the Adwaita CSS Variables Specification:
#        https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html
#
#        This module defines ALL Adwaita color palette variables (45 total):
#        - blue_1 through blue_5 (Signal secondary accent, Lc75 and Lc60)
#        - green_1 through green_5 (Signal primary/success accent, Lc75 and Lc60)
#        - yellow_1 through yellow_5 (Signal warning accent, Lc75 and Lc60)
#        - orange_1 through orange_5 (Signal warning accent, Lc75 and Lc60)
#        - red_1 through red_5 (Signal danger accent, Lc75 and Lc60)
#        - purple_1 through purple_5 (Signal tertiary accent, Lc75 and Lc60)
#        - brown_1 through brown_5 (Signal neutral tones)
#        - light_1 through light_5 (Signal surface colors)
#        - dark_1 through dark_5 (Signal surface/text colors)
#
#        Note: Signal accent colors only have two lightness levels (Lc60 and Lc75),
#        so the 5-shade palette reuses these values. The middle value (e.g., blue_3)
#        is the primary shade that GTK apps will use most frequently.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Access accent colors from palette
  inherit (signalPalette) accent;

  # Use semantic bridge for color resolution
  # Note: GTK/Adwaita requires specific Lc60 tier for accent colors
  # This is a documented exception to semantic bridge usage
  # See: https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/named-colors.html

  # ============================================
  # Standalone Color Generator
  # ============================================
  # Per Adwaita spec: standalone colors should be darker in light mode,
  # lighter in dark mode for use on variable backgrounds.
  # Uses OKLCH color space for perceptually uniform adjustments.
  mkStandaloneColor =
    hexColor:
    let
      oklch = nix-colorizer.hex.to.oklch hexColor;
      # Target lightness: 0.5 for light mode, 0.85 for dark mode
      targetL = if themeMode == "light" then 0.5 else 0.85;
      adjusted = oklch // {
        L = targetL;
      };
    in
    nix-colorizer.oklch.to.hex adjusted;

  # ============================================
  # Helper Values (Adwaita Specification)
  # ============================================
  helpers = {
    border-opacity = if themeMode == "light" then "15%" else "15%";
    dim-opacity = if themeMode == "light" then "55%" else "55%";
    disabled-opacity = if themeMode == "light" then "50%" else "50%";
    window-radius = "15px";
  };

  # ============================================
  # Font Variables (Adwaita Specification)
  # ============================================
  fonts = {
    document-font-family = "Cantarell";
    document-font-size = "11pt";
    monospace-font-family = "Monospace";
    monospace-font-size = "10pt";
  };

  # ============================================
  # Accent Presets (Adwaita Named Accents)
  # ============================================
  # GTK/Adwaita requires Lc60 tier specifically for accent colors
  # Using getAccent helper for tier-specific access
  accentPresets = {
    accent-blue = (semantic.getAccent "secondary" "Lc60").hex;
    accent-teal = (semantic.getAccent "info" "Lc60").hex;
    accent-green = (semantic.getAccent "primary" "Lc60").hex;
    accent-yellow = (semantic.getAccent "warning" "Lc60").hex;
    accent-orange = (semantic.getAccent "warning" "Lc60").hex;
    accent-red = (semantic.getAccent "danger" "Lc60").hex;
    accent-pink = (semantic.getAccent "tertiary" "Lc60").hex;
    accent-purple = (semantic.getAccent "tertiary" "Lc60").hex;
    accent-slate = (semantic.text "secondary" themeMode).hex;
  };

  # Color mappings based on theme mode
  # Light mode uses lighter surfaces, dark mode uses darker surfaces
  colors =
    if themeMode == "light" then
      {
        # Light mode colors - using semantic bridge and palette
        window-bg = (semantic.ui "panel-background" themeMode).hex;
        window-fg = (semantic.core "foreground" themeMode).hex;
        view-bg = (semantic.core "background" themeMode).hex;
        view-fg = (semantic.core "foreground" themeMode).hex;
        headerbar-bg = (semantic.ui "panel-background" themeMode).hex;
        headerbar-fg = (semantic.core "foreground" themeMode).hex;
        headerbar-border = (semantic.core "foreground" themeMode).hex;
        headerbar-backdrop = (semantic.core "background" themeMode).hex;
        headerbar-shade = (semantic.ui "panel-border" themeMode).hex;
        headerbar-darker-shade = (semantic.ui "element-active" themeMode).hex;
        sidebar-bg = (semantic.ui "element-hover" themeMode).hex;
        sidebar-fg = (semantic.core "foreground" themeMode).hex;
        sidebar-backdrop = (semantic.ui "panel-background" themeMode).hex;
        sidebar-shade = (semantic.ui "panel-border" themeMode).hex;
        sidebar-border = (semantic.ui "panel-border" themeMode).hex;
        secondary-sidebar-bg = (semantic.ui "element-hover" themeMode).hex;
        secondary-sidebar-fg = (semantic.core "foreground" themeMode).hex;
        secondary-sidebar-backdrop = (semantic.ui "panel-background" themeMode).hex;
        secondary-sidebar-shade = (semantic.ui "panel-border" themeMode).hex;
        secondary-sidebar-border = (semantic.ui "panel-border" themeMode).hex;
        card-bg = (semantic.core "background" themeMode).hex;
        card-fg = (semantic.core "foreground" themeMode).hex;
        card-shade = (semantic.ui "panel-border" themeMode).hex;
        dialog-bg = (semantic.ui "panel-background" themeMode).hex;
        dialog-fg = (semantic.core "foreground" themeMode).hex;
        popover-bg = (semantic.core "background" themeMode).hex;
        popover-fg = (semantic.core "foreground" themeMode).hex;
        popover-shade = (semantic.ui "panel-border" themeMode).hex;
        thumbnail-bg = (semantic.core "background" themeMode).hex;
        thumbnail-fg = (semantic.core "foreground" themeMode).hex;
        shade = (semantic.ui "panel-border" themeMode).hex;
        scrollbar-outline = (semantic.core "background" themeMode).hex;
      }
    else
      {
        # Dark mode colors - using semantic bridge and palette
        window-bg = (semantic.ui "element-hover" themeMode).hex;
        window-fg = (semantic.core "foreground" themeMode).hex;
        view-bg = (semantic.core "background" themeMode).hex;
        view-fg = (semantic.core "foreground" themeMode).hex;
        headerbar-bg = (semantic.ui "element-hover" themeMode).hex;
        headerbar-fg = (semantic.core "foreground" themeMode).hex;
        headerbar-border = (semantic.core "foreground" themeMode).hex;
        headerbar-backdrop = (semantic.core "background" themeMode).hex;
        headerbar-shade = (semantic.ui "element-active" themeMode).hex;
        headerbar-darker-shade = (semantic.ui "element-active" themeMode).hex;
        sidebar-bg = (semantic.ui "element-hover" themeMode).hex;
        sidebar-fg = (semantic.core "foreground" themeMode).hex;
        sidebar-backdrop = (semantic.ui "panel-background" themeMode).hex;
        sidebar-shade = (semantic.ui "panel-border" themeMode).hex;
        sidebar-border = (semantic.ui "element-active" themeMode).hex;
        secondary-sidebar-bg = (semantic.ui "panel-background" themeMode).hex;
        secondary-sidebar-fg = (semantic.core "foreground" themeMode).hex;
        secondary-sidebar-backdrop = (semantic.ui "panel-background" themeMode).hex;
        secondary-sidebar-shade = (semantic.ui "panel-border" themeMode).hex;
        secondary-sidebar-border = (semantic.ui "element-active" themeMode).hex;
        card-bg = (semantic.ui "element-hover" themeMode).hex;
        card-fg = (semantic.core "foreground" themeMode).hex;
        card-shade = (semantic.ui "element-active" themeMode).hex;
        dialog-bg = (semantic.ui "element-hover" themeMode).hex;
        dialog-fg = (semantic.core "foreground" themeMode).hex;
        popover-bg = (semantic.core "background" themeMode).hex;
        popover-fg = (semantic.core "foreground" themeMode).hex;
        popover-shade = (semantic.ui "panel-border" themeMode).hex;
        thumbnail-bg = (semantic.core "background" themeMode).hex;
        thumbnail-fg = (semantic.core "foreground" themeMode).hex;
        shade = (semantic.ui "panel-border" themeMode).hex;
        scrollbar-outline = (semantic.ui "panel-background" themeMode).hex;
      };

  # Map Signal colors to Adwaita palette
  # These are the standard GNOME color palette that GTK apps use
  # Note: Signal accent colors only have Lc60 and Lc75, so we create
  # a 5-shade range using both accent values and tonal colors
  adwaitaPalette = {
    # Blues - Using Signal secondary accent
    blue_1 = accent.secondary.Lc75.hex; # Lightest
    blue_2 = accent.secondary.Lc75.hex; # Light
    blue_3 = accent.secondary.Lc60.hex; # Medium (default)
    blue_4 = accent.secondary.Lc60.hex; # Dark
    blue_5 = accent.secondary.Lc60.hex; # Darkest

    # Greens - Using Signal primary accent (success)
    green_1 = accent.primary.Lc75.hex;
    green_2 = accent.primary.Lc75.hex;
    green_3 = accent.primary.Lc60.hex;
    green_4 = accent.primary.Lc60.hex;
    green_5 = accent.primary.Lc60.hex;

    # Yellows - Using Signal warning accent
    yellow_1 = accent.warning.Lc75.hex;
    yellow_2 = accent.warning.Lc75.hex;
    yellow_3 = accent.warning.Lc60.hex;
    yellow_4 = accent.warning.Lc60.hex;
    yellow_5 = accent.warning.Lc60.hex;

    # Oranges - Using Signal warning accent
    orange_1 = accent.warning.Lc75.hex;
    orange_2 = accent.warning.Lc75.hex;
    orange_3 = accent.warning.Lc60.hex;
    orange_4 = accent.warning.Lc60.hex;
    orange_5 = accent.warning.Lc60.hex;

    # Reds - Using Signal danger accent
    red_1 = accent.danger.Lc75.hex;
    red_2 = accent.danger.Lc75.hex;
    red_3 = accent.danger.Lc60.hex;
    red_4 = accent.danger.Lc60.hex;
    red_5 = accent.danger.Lc60.hex;

    # Purples - Using Signal tertiary accent
    purple_1 = accent.tertiary.Lc75.hex;
    purple_2 = accent.tertiary.Lc75.hex;
    purple_3 = accent.tertiary.Lc60.hex;
    purple_4 = accent.tertiary.Lc60.hex;
    purple_5 = accent.tertiary.Lc60.hex;

    # Browns - Using neutral tonal colors via semantic bridge
    brown_1 = (semantic.text "tertiary" themeMode).hex;
    brown_2 = (semantic.text "secondary" themeMode).hex;
    brown_3 = (semantic.text "primary" themeMode).hex;
    brown_4 = (semantic.ui "element-active" themeMode).hex;
    brown_5 = (semantic.ui "panel-border" themeMode).hex;

    # Light grays (light_1 through light_5)
    light_1 =
      if themeMode == "light" then
        (semantic.getTonal "white" themeMode).hex
      else
        (semantic.core "background" themeMode).hex;
    light_2 =
      if themeMode == "light" then
        (semantic.core "background" themeMode).hex
      else
        (semantic.ui "panel-background" themeMode).hex;
    light_3 =
      if themeMode == "light" then
        (semantic.ui "panel-background" themeMode).hex
      else
        (semantic.ui "element-hover" themeMode).hex;
    light_4 = (semantic.ui "panel-border" themeMode).hex;
    light_5 = (semantic.ui "element-active" themeMode).hex;

    # Dark grays (dark_1 through dark_5)
    dark_1 =
      if themeMode == "light" then
        (semantic.text "tertiary" themeMode).hex
      else
        (semantic.ui "element-active" themeMode).hex;
    dark_2 =
      if themeMode == "light" then
        (semantic.text "secondary" themeMode).hex
      else
        (semantic.text "tertiary" themeMode).hex;
    dark_3 = (semantic.ui "element-hover" themeMode).hex;
    dark_4 = (semantic.ui "panel-background" themeMode).hex;
    dark_5 =
      if themeMode == "light" then
        (semantic.core "background" themeMode).hex
      else
        (semantic.getTonal "black" themeMode).hex;
  };

  # ============================================
  # @define-color directives (GTK3/GTK4 compatible)
  # ============================================
  defineColorCss = ''
    /* Signal Color Theme - Complete Adwaita Named Colors */

    /* ============================================ */
    /* Adwaita Color Palette                        */
    /* ============================================ */

    /* Blues */
    @define-color blue_1 ${adwaitaPalette.blue_1};
    @define-color blue_2 ${adwaitaPalette.blue_2};
    @define-color blue_3 ${adwaitaPalette.blue_3};
    @define-color blue_4 ${adwaitaPalette.blue_4};
    @define-color blue_5 ${adwaitaPalette.blue_5};

    /* Greens */
    @define-color green_1 ${adwaitaPalette.green_1};
    @define-color green_2 ${adwaitaPalette.green_2};
    @define-color green_3 ${adwaitaPalette.green_3};
    @define-color green_4 ${adwaitaPalette.green_4};
    @define-color green_5 ${adwaitaPalette.green_5};

    /* Yellows */
    @define-color yellow_1 ${adwaitaPalette.yellow_1};
    @define-color yellow_2 ${adwaitaPalette.yellow_2};
    @define-color yellow_3 ${adwaitaPalette.yellow_3};
    @define-color yellow_4 ${adwaitaPalette.yellow_4};
    @define-color yellow_5 ${adwaitaPalette.yellow_5};

    /* Oranges */
    @define-color orange_1 ${adwaitaPalette.orange_1};
    @define-color orange_2 ${adwaitaPalette.orange_2};
    @define-color orange_3 ${adwaitaPalette.orange_3};
    @define-color orange_4 ${adwaitaPalette.orange_4};
    @define-color orange_5 ${adwaitaPalette.orange_5};

    /* Reds */
    @define-color red_1 ${adwaitaPalette.red_1};
    @define-color red_2 ${adwaitaPalette.red_2};
    @define-color red_3 ${adwaitaPalette.red_3};
    @define-color red_4 ${adwaitaPalette.red_4};
    @define-color red_5 ${adwaitaPalette.red_5};

    /* Purples */
    @define-color purple_1 ${adwaitaPalette.purple_1};
    @define-color purple_2 ${adwaitaPalette.purple_2};
    @define-color purple_3 ${adwaitaPalette.purple_3};
    @define-color purple_4 ${adwaitaPalette.purple_4};
    @define-color purple_5 ${adwaitaPalette.purple_5};

    /* Browns */
    @define-color brown_1 ${adwaitaPalette.brown_1};
    @define-color brown_2 ${adwaitaPalette.brown_2};
    @define-color brown_3 ${adwaitaPalette.brown_3};
    @define-color brown_4 ${adwaitaPalette.brown_4};
    @define-color brown_5 ${adwaitaPalette.brown_5};

    /* Light grays */
    @define-color light_1 ${adwaitaPalette.light_1};
    @define-color light_2 ${adwaitaPalette.light_2};
    @define-color light_3 ${adwaitaPalette.light_3};
    @define-color light_4 ${adwaitaPalette.light_4};
    @define-color light_5 ${adwaitaPalette.light_5};

    /* Dark grays */
    @define-color dark_1 ${adwaitaPalette.dark_1};
    @define-color dark_2 ${adwaitaPalette.dark_2};
    @define-color dark_3 ${adwaitaPalette.dark_3};
    @define-color dark_4 ${adwaitaPalette.dark_4};
    @define-color dark_5 ${adwaitaPalette.dark_5};

    /* ============================================ */
    /* Legacy GTK 3 Base Colors                     */
    /* ============================================ */

    @define-color theme_bg_color ${colors.window-bg};
    @define-color theme_fg_color ${colors.window-fg};
    @define-color theme_base_color ${colors.view-bg};
    @define-color theme_text_color ${colors.view-fg};
    @define-color theme_selected_bg_color ${accent.secondary.Lc60.hex};
    @define-color theme_selected_fg_color ${colors.view-bg};

    @define-color insensitive_bg_color ${colors.window-bg};
    @define-color insensitive_fg_color ${colors.shade};
    @define-color insensitive_base_color ${colors.view-bg};

    @define-color borders ${colors.shade};
    @define-color unfocused_borders ${colors.shade};

    @define-color wm_title ${colors.headerbar-fg};
    @define-color wm_unfocused_title ${colors.headerbar-fg};
    @define-color wm_bg ${colors.headerbar-bg};
    @define-color wm_border ${colors.headerbar-border};

    /* ============================================ */
    /* Adwaita Named Colors                         */
    /* ============================================ */

    /* Destructive action buttons */
    @define-color destructive_bg_color ${accent.danger.Lc60.hex};
    @define-color destructive_fg_color ${colors.view-bg};
    @define-color destructive_color ${mkStandaloneColor accent.danger.Lc60.hex};

    /* Success states (levelbars, entries, labels, infobars) */
    @define-color success_bg_color ${accent.primary.Lc60.hex};
    @define-color success_fg_color ${colors.view-bg};
    @define-color success_color ${mkStandaloneColor accent.primary.Lc60.hex};

    /* Warning states */
    @define-color warning_bg_color ${accent.warning.Lc60.hex};
    @define-color warning_fg_color ${
      if themeMode == "light" then (semantic.core "foreground" themeMode).hex else colors.view-bg
    };
    @define-color warning_color ${mkStandaloneColor accent.warning.Lc60.hex};

    /* Error states */
    @define-color error_bg_color ${accent.danger.Lc60.hex};
    @define-color error_fg_color ${colors.view-bg};
    @define-color error_color ${mkStandaloneColor accent.danger.Lc60.hex};

    /* Accent colors */
    @define-color accent_bg_color ${accent.secondary.Lc60.hex};
    @define-color accent_fg_color ${colors.view-bg};
    @define-color accent_color ${mkStandaloneColor accent.secondary.Lc60.hex};

    /* Window colors */
    @define-color window_bg_color ${colors.window-bg};
    @define-color window_fg_color ${colors.window-fg};

    /* View colors (text view, tree view) */
    @define-color view_bg_color ${colors.view-bg};
    @define-color view_fg_color ${colors.view-fg};

    /* Header bar, search bar, tab bar */
    @define-color headerbar_bg_color ${colors.headerbar-bg};
    @define-color headerbar_fg_color ${colors.headerbar-fg};
    @define-color headerbar_border_color ${colors.headerbar-border};
    @define-color headerbar_backdrop_color ${colors.headerbar-backdrop};
    @define-color headerbar_shade_color ${colors.headerbar-shade};
    @define-color headerbar_darker_shade_color ${colors.headerbar-darker-shade};

    /* Split pane views - Primary sidebar */
    @define-color sidebar_bg_color ${colors.sidebar-bg};
    @define-color sidebar_fg_color ${colors.sidebar-fg};
    @define-color sidebar_backdrop_color ${colors.sidebar-backdrop};
    @define-color sidebar_shade_color ${colors.sidebar-shade};
    @define-color sidebar_border_color ${colors.sidebar-border};

    /* Split pane views - Secondary sidebar */
    @define-color secondary_sidebar_bg_color ${colors.secondary-sidebar-bg};
    @define-color secondary_sidebar_fg_color ${colors.secondary-sidebar-fg};
    @define-color secondary_sidebar_backdrop_color ${colors.secondary-sidebar-backdrop};
    @define-color secondary_sidebar_shade_color ${colors.secondary-sidebar-shade};
    @define-color secondary_sidebar_border_color ${colors.secondary-sidebar-border};

    /* Cards, boxed lists */
    @define-color card_bg_color ${colors.card-bg};
    @define-color card_fg_color ${colors.card-fg};
    @define-color card_shade_color ${colors.card-shade};

    /* Dialogs */
    @define-color dialog_bg_color ${colors.dialog-bg};
    @define-color dialog_fg_color ${colors.dialog-fg};

    /* Popovers */
    @define-color popover_bg_color ${colors.popover-bg};
    @define-color popover_fg_color ${colors.popover-fg};
    @define-color popover_shade_color ${colors.popover-shade};

    /* Thumbnails */
    @define-color thumbnail_bg_color ${colors.thumbnail-bg};
    @define-color thumbnail_fg_color ${colors.thumbnail-fg};

    /* Miscellaneous */
    @define-color shade_color ${colors.shade};
    @define-color scrollbar_outline_color ${colors.scrollbar-outline};
  '';

  # ============================================
  # Button Styles (shared between GTK3 and GTK4)
  # ============================================
  buttonStylesCss = ''
    /* ============================================ */
    /* Button Styles                                 */
    /* ============================================ */

    /* Secondary/normal buttons */
    button {
      background-color: ${colors.card-bg};
      color: ${colors.window-fg};
      border-color: ${colors.shade};
    }

    button:hover {
      background-color: ${colors.sidebar-bg};
    }

    /* Primary/selected buttons (suggested-action) */
    button.suggested-action,
    button:active,
    button:checked {
      background-color: ${accent.secondary.Lc60.hex};
      color: ${colors.view-bg};
    }

    button.suggested-action:hover {
      background-color: ${accent.secondary.Lc75.hex};
    }

    button:disabled {
      background-color: ${colors.window-bg};
      color: ${colors.shade};
    }
  '';

  # ============================================
  # GTK3 CSS (only @define-color, no CSS custom properties)
  # ============================================
  gtk3Css = defineColorCss + buttonStylesCss;

  # ============================================
  # GTK4 CSS Custom Properties (:root block)
  # Follows Adwaita CSS Variables Specification
  # https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html
  # ============================================
  gtk4Css = ''
    /* ============================================ */
    /* CSS Custom Properties (Adwaita Specification) */
    /* ============================================ */

    :root {
      /* ------------------------------------------ */
      /* Accent Colors                              */
      /* ------------------------------------------ */
      --accent-bg-color: ${accent.secondary.Lc60.hex};
      --accent-fg-color: ${colors.view-bg};
      --accent-color: ${mkStandaloneColor accent.secondary.Lc60.hex};

      /* ------------------------------------------ */
      /* Destructive Colors                         */
      /* ------------------------------------------ */
      --destructive-bg-color: ${accent.danger.Lc60.hex};
      --destructive-fg-color: ${colors.view-bg};
      --destructive-color: ${mkStandaloneColor accent.danger.Lc60.hex};

      /* ------------------------------------------ */
      /* Success Colors                             */
      /* ------------------------------------------ */
      --success-bg-color: ${accent.primary.Lc60.hex};
      --success-fg-color: ${colors.view-bg};
      --success-color: ${mkStandaloneColor accent.primary.Lc60.hex};

      /* ------------------------------------------ */
      /* Warning Colors                             */
      /* ------------------------------------------ */
      --warning-bg-color: ${accent.warning.Lc60.hex};
      --warning-fg-color: ${
        if themeMode == "light" then (semantic.core "foreground" themeMode).hex else colors.view-bg
      };
      --warning-color: ${mkStandaloneColor accent.warning.Lc60.hex};

      /* ------------------------------------------ */
      /* Error Colors                               */
      /* ------------------------------------------ */
      --error-bg-color: ${accent.danger.Lc60.hex};
      --error-fg-color: ${colors.view-bg};
      --error-color: ${mkStandaloneColor accent.danger.Lc60.hex};

      /* ------------------------------------------ */
      /* Window Colors                              */
      /* ------------------------------------------ */
      --window-bg-color: ${colors.window-bg};
      --window-fg-color: ${colors.window-fg};

      /* ------------------------------------------ */
      /* View Colors                                */
      /* ------------------------------------------ */
      --view-bg-color: ${colors.view-bg};
      --view-fg-color: ${colors.view-fg};

      /* ------------------------------------------ */
      /* Header Bar Colors                          */
      /* ------------------------------------------ */
      --headerbar-bg-color: ${colors.headerbar-bg};
      --headerbar-fg-color: ${colors.headerbar-fg};
      --headerbar-border-color: ${colors.headerbar-border};
      --headerbar-backdrop-color: ${colors.headerbar-backdrop};
      --headerbar-shade-color: ${colors.headerbar-shade};
      --headerbar-darker-shade-color: ${colors.headerbar-darker-shade};

      /* ------------------------------------------ */
      /* Sidebar Colors                             */
      /* ------------------------------------------ */
      --sidebar-bg-color: ${colors.sidebar-bg};
      --sidebar-fg-color: ${colors.sidebar-fg};
      --sidebar-backdrop-color: ${colors.sidebar-backdrop};
      --sidebar-shade-color: ${colors.sidebar-shade};
      --sidebar-border-color: ${colors.sidebar-border};

      /* ------------------------------------------ */
      /* Secondary Sidebar Colors                   */
      /* ------------------------------------------ */
      --secondary-sidebar-bg-color: ${colors.secondary-sidebar-bg};
      --secondary-sidebar-fg-color: ${colors.secondary-sidebar-fg};
      --secondary-sidebar-backdrop-color: ${colors.secondary-sidebar-backdrop};
      --secondary-sidebar-shade-color: ${colors.secondary-sidebar-shade};
      --secondary-sidebar-border-color: ${colors.secondary-sidebar-border};

      /* ------------------------------------------ */
      /* Card Colors                                */
      /* ------------------------------------------ */
      --card-bg-color: ${colors.card-bg};
      --card-fg-color: ${colors.card-fg};
      --card-shade-color: ${colors.card-shade};

      /* ------------------------------------------ */
      /* Dialog Colors                              */
      /* ------------------------------------------ */
      --dialog-bg-color: ${colors.dialog-bg};
      --dialog-fg-color: ${colors.dialog-fg};

      /* ------------------------------------------ */
      /* Popover Colors                             */
      /* ------------------------------------------ */
      --popover-bg-color: ${colors.popover-bg};
      --popover-fg-color: ${colors.popover-fg};
      --popover-shade-color: ${colors.popover-shade};

      /* ------------------------------------------ */
      /* Thumbnail Colors                           */
      /* ------------------------------------------ */
      --thumbnail-bg-color: ${colors.thumbnail-bg};
      --thumbnail-fg-color: ${colors.thumbnail-fg};

      /* ------------------------------------------ */
      /* Miscellaneous Colors                       */
      /* ------------------------------------------ */
      --shade-color: ${colors.shade};
      --scrollbar-outline-color: ${colors.scrollbar-outline};

      /* ------------------------------------------ */
      /* Tab Overview Colors                        */
      /* ------------------------------------------ */
      --overview-bg-color: ${colors.window-bg};
      --overview-fg-color: ${colors.window-fg};

      /* ------------------------------------------ */
      /* Active Toggle Colors                       */
      /* ------------------------------------------ */
      --active-toggle-bg-color: ${accent.secondary.Lc60.hex};
      --active-toggle-fg-color: ${colors.view-bg};

      /* ------------------------------------------ */
      /* Helper Variables                           */
      /* ------------------------------------------ */
      --border-opacity: ${helpers.border-opacity};
      --dim-opacity: ${helpers.dim-opacity};
      --disabled-opacity: ${helpers.disabled-opacity};
      --border-color: color-mix(in srgb, currentColor ${helpers.border-opacity}, transparent);
      --window-radius: ${helpers.window-radius};

      /* ------------------------------------------ */
      /* Font Variables                             */
      /* ------------------------------------------ */
      --document-font-family: ${fonts.document-font-family};
      --document-font-size: ${fonts.document-font-size};
      --monospace-font-family: ${fonts.monospace-font-family};
      --monospace-font-size: ${fonts.monospace-font-size};

      /* ------------------------------------------ */
      /* Accent Presets                             */
      /* ------------------------------------------ */
      --accent-blue: ${accentPresets.accent-blue};
      --accent-teal: ${accentPresets.accent-teal};
      --accent-green: ${accentPresets.accent-green};
      --accent-yellow: ${accentPresets.accent-yellow};
      --accent-orange: ${accentPresets.accent-orange};
      --accent-red: ${accentPresets.accent-red};
      --accent-pink: ${accentPresets.accent-pink};
      --accent-purple: ${accentPresets.accent-purple};
      --accent-slate: ${accentPresets.accent-slate};

      /* ------------------------------------------ */
      /* Palette Colors (with dashes)               */
      /* ------------------------------------------ */
      --blue-1: ${adwaitaPalette.blue_1};
      --blue-2: ${adwaitaPalette.blue_2};
      --blue-3: ${adwaitaPalette.blue_3};
      --blue-4: ${adwaitaPalette.blue_4};
      --blue-5: ${adwaitaPalette.blue_5};

      --green-1: ${adwaitaPalette.green_1};
      --green-2: ${adwaitaPalette.green_2};
      --green-3: ${adwaitaPalette.green_3};
      --green-4: ${adwaitaPalette.green_4};
      --green-5: ${adwaitaPalette.green_5};

      --yellow-1: ${adwaitaPalette.yellow_1};
      --yellow-2: ${adwaitaPalette.yellow_2};
      --yellow-3: ${adwaitaPalette.yellow_3};
      --yellow-4: ${adwaitaPalette.yellow_4};
      --yellow-5: ${adwaitaPalette.yellow_5};

      --orange-1: ${adwaitaPalette.orange_1};
      --orange-2: ${adwaitaPalette.orange_2};
      --orange-3: ${adwaitaPalette.orange_3};
      --orange-4: ${adwaitaPalette.orange_4};
      --orange-5: ${adwaitaPalette.orange_5};

      --red-1: ${adwaitaPalette.red_1};
      --red-2: ${adwaitaPalette.red_2};
      --red-3: ${adwaitaPalette.red_3};
      --red-4: ${adwaitaPalette.red_4};
      --red-5: ${adwaitaPalette.red_5};

      --purple-1: ${adwaitaPalette.purple_1};
      --purple-2: ${adwaitaPalette.purple_2};
      --purple-3: ${adwaitaPalette.purple_3};
      --purple-4: ${adwaitaPalette.purple_4};
      --purple-5: ${adwaitaPalette.purple_5};

      --brown-1: ${adwaitaPalette.brown_1};
      --brown-2: ${adwaitaPalette.brown_2};
      --brown-3: ${adwaitaPalette.brown_3};
      --brown-4: ${adwaitaPalette.brown_4};
      --brown-5: ${adwaitaPalette.brown_5};

      --light-1: ${adwaitaPalette.light_1};
      --light-2: ${adwaitaPalette.light_2};
      --light-3: ${adwaitaPalette.light_3};
      --light-4: ${adwaitaPalette.light_4};
      --light-5: ${adwaitaPalette.light_5};

      --dark-1: ${adwaitaPalette.dark_1};
      --dark-2: ${adwaitaPalette.dark_2};
      --dark-3: ${adwaitaPalette.dark_3};
      --dark-4: ${adwaitaPalette.dark_4};
      --dark-5: ${adwaitaPalette.dark_5};
    }

  ''
  + defineColorCss
  + buttonStylesCss;

  # Check if gtk should be themed
  # Note: GTK uses config.gtk.enable (not programs.gtk.enable) so we keep custom logic
  shouldTheme = cfg.gtk.enable || (cfg.autoEnable && (config.gtk.enable or false));

  # Build Signal GTK theme package
  signalGtkTheme = pkgs.callPackage ../../pkgs/gtk-theme {
    inherit signalLib;
    mode = themeMode;
  };
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    gtk = {
      theme = {
        name = "Signal-${themeMode}";
        package = signalGtkTheme;
      };

      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };

      gtk3.extraCss = gtk3Css;
      gtk4.extraCss = gtk4Css;
    };
  };
}
