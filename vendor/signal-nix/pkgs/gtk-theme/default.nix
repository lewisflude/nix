{
  lib,
  stdenv,
  signalLib,
  mode ? "dark",
}:

let
  inherit (lib) removePrefix;

  # Resolve theme mode
  themeMode = signalLib.resolveThemeMode mode;
  colors = signalLib.getColors themeMode;

  # Extract colors for GTK theme
  surface-base = colors.tonal."surface-base";
  surface-subtle = colors.tonal."surface-subtle";
  surface-emphasis = colors.tonal."surface-hover";
  text-primary = colors.tonal."text-primary";
  text-secondary = colors.tonal."text-secondary";
  text-tertiary = colors.tonal."text-tertiary";
  divider-primary = colors.tonal."divider-primary";
  divider-secondary = colors.tonal."divider-strong";

  inherit (colors) accent;

  # Generate comprehensive GTK CSS for both GTK3 and GTK4
  gtkCss = ''
    /* Signal Design System - GTK Theme
     * Mode: ${themeMode}
     * Generated from signal-palette with OKLCH colors
     */

    /* ========================================================================
     * Base Color Definitions (GTK3 & GTK4 compatible)
     * ======================================================================== */

    @define-color theme_bg_color ${surface-base.hex};
    @define-color theme_fg_color ${text-primary.hex};
    @define-color theme_base_color ${surface-base.hex};
    @define-color theme_text_color ${text-primary.hex};
    @define-color theme_selected_bg_color ${accent.secondary.Lc75.hex};
    @define-color theme_selected_fg_color ${surface-base.hex};

    /* Insensitive (disabled) states */
    @define-color insensitive_bg_color ${surface-subtle.hex};
    @define-color insensitive_fg_color ${text-tertiary.hex};
    @define-color insensitive_base_color ${surface-subtle.hex};

    /* Borders and dividers */
    @define-color borders ${divider-primary.hex};
    @define-color unfocused_borders ${divider-primary.hex};
    @define-color divider_color ${divider-primary.hex};

    /* State colors */
    @define-color warning_color ${accent.warning.Lc75.hex};
    @define-color error_color ${accent.danger.Lc75.hex};
    @define-color success_color ${accent.primary.Lc75.hex};

    /* Window decorations */
    @define-color wm_title ${text-primary.hex};
    @define-color wm_unfocused_title ${text-secondary.hex};
    @define-color wm_bg ${surface-base.hex};
    @define-color wm_border ${divider-secondary.hex};

    /* Modern GTK4 semantic colors */
    @define-color accent_bg_color ${accent.secondary.Lc75.hex};
    @define-color accent_fg_color ${surface-base.hex};
    @define-color accent_color ${accent.secondary.Lc75.hex};
    @define-color destructive_bg_color ${accent.danger.Lc75.hex};
    @define-color destructive_fg_color ${surface-base.hex};
    @define-color destructive_color ${accent.danger.Lc75.hex};

    /* View colors */
    @define-color view_bg_color ${surface-base.hex};
    @define-color view_fg_color ${text-primary.hex};

    /* Hover states */
    @define-color theme_hover_color ${surface-subtle.hex};

    /* Card backgrounds */
    @define-color card_bg_color ${surface-subtle.hex};
    @define-color card_fg_color ${text-primary.hex};

    /* Dialog backgrounds */
    @define-color dialog_bg_color ${surface-base.hex};
    @define-color dialog_fg_color ${text-primary.hex};

    /* Popover backgrounds */
    @define-color popover_bg_color ${surface-subtle.hex};
    @define-color popover_fg_color ${text-primary.hex};

    /* Sidebar colors */
    @define-color sidebar_bg_color ${surface-emphasis.hex};
    @define-color sidebar_fg_color ${text-primary.hex};

    /* Header bar colors */
    @define-color headerbar_bg_color ${surface-emphasis.hex};
    @define-color headerbar_fg_color ${text-primary.hex};
    @define-color headerbar_border_color ${divider-secondary.hex};

    /* ========================================================================
     * GTK3-Specific Overrides
     * ======================================================================== */

    /* GTK3 window and dialog backgrounds */
    GtkWindow,
    GtkDialog,
    GtkMessageDialog {
      background-color: ${surface-base.hex};
      color: ${text-primary.hex};
    }

    /* GTK3 message dialog styling (used by pinentry) */
    GtkMessageDialog .titlebar,
    GtkMessageDialog .dialog-vbox {
      background-color: ${surface-base.hex};
    }

    GtkMessageDialog .message-area {
      background-color: ${surface-base.hex};
      color: ${text-primary.hex};
    }

    /* Buttons */
    button {
      background-color: ${surface-emphasis.hex};
      color: ${text-primary.hex};
      border-color: ${divider-primary.hex};
    }

    button:hover {
      background-color: ${surface-subtle.hex};
    }

    button:active,
    button:checked {
      background-color: ${accent.secondary.Lc75.hex};
      color: ${surface-base.hex};
    }

    button:disabled {
      background-color: ${surface-subtle.hex};
      color: ${text-tertiary.hex};
    }

    /* Entries (text inputs) */
    entry {
      background-color: ${surface-base.hex};
      color: ${text-primary.hex};
      border-color: ${divider-primary.hex};
    }

    entry:focus {
      border-color: ${accent.secondary.Lc75.hex};
    }

    entry:disabled {
      background-color: ${surface-subtle.hex};
      color: ${text-tertiary.hex};
    }

    /* Selections */
    selection,
    *:selected {
      background-color: ${accent.secondary.Lc75.hex};
      color: ${surface-base.hex};
    }

    /* Lists and tree views */
    list,
    treeview {
      background-color: ${surface-base.hex};
      color: ${text-primary.hex};
    }

    list row:hover,
    treeview row:hover {
      background-color: ${surface-subtle.hex};
    }

    list row:selected,
    treeview row:selected {
      background-color: ${accent.secondary.Lc75.hex};
      color: ${surface-base.hex};
    }

    /* Scrollbars */
    scrollbar slider {
      background-color: ${divider-secondary.hex};
    }

    scrollbar slider:hover {
      background-color: ${text-tertiary.hex};
    }

    /* Tooltips */
    tooltip {
      background-color: ${surface-emphasis.hex};
      color: ${text-primary.hex};
      border-color: ${divider-secondary.hex};
    }

    /* Menus */
    menu,
    .menu {
      background-color: ${surface-emphasis.hex};
      color: ${text-primary.hex};
      border-color: ${divider-secondary.hex};
    }

    menuitem:hover {
      background-color: ${surface-subtle.hex};
    }

    menuitem:active {
      background-color: ${accent.secondary.Lc75.hex};
      color: ${surface-base.hex};
    }

    /* Notebooks (tabs) */
    notebook {
      background-color: ${surface-base.hex};
    }

    notebook header {
      background-color: ${surface-emphasis.hex};
      border-color: ${divider-primary.hex};
    }

    notebook tab {
      background-color: ${surface-emphasis.hex};
      color: ${text-secondary.hex};
    }

    notebook tab:hover {
      background-color: ${surface-subtle.hex};
      color: ${text-primary.hex};
    }

    notebook tab:checked {
      background-color: ${surface-base.hex};
      color: ${text-primary.hex};
      border-color: ${accent.secondary.Lc75.hex};
    }

    /* Popovers */
    popover,
    .popover {
      background-color: ${surface-emphasis.hex};
      color: ${text-primary.hex};
      border-color: ${divider-secondary.hex};
    }

    /* Progress bars */
    progressbar {
      background-color: ${surface-subtle.hex};
    }

    progressbar progress {
      background-color: ${accent.secondary.Lc75.hex};
    }

    /* Switches */
    switch {
      background-color: ${surface-subtle.hex};
    }

    switch:checked {
      background-color: ${accent.secondary.Lc75.hex};
    }

    switch slider {
      background-color: ${surface-base.hex};
    }

    /* Check boxes and radio buttons */
    checkbutton:checked,
    radiobutton:checked {
      background-color: ${accent.secondary.Lc75.hex};
      color: ${surface-base.hex};
    }

    /* Links */
    link,
    *:link {
      color: ${accent.secondary.Lc75.hex};
    }

    link:visited,
    *:visited {
      color: ${accent.tertiary.Lc75.hex};
    }

    /* ========================================================================
     * GTK4-Specific Overrides
     * ======================================================================== */

    /* Modern GTK4 widgets use the @define-color variables above,
     * but we can add explicit overrides for consistency */

    window {
      background-color: ${surface-base.hex};
      color: ${text-primary.hex};
    }

    /* Dialog windows (including pinentry) */
    dialog,
    messagedialog,
    window.dialog,
    window.messagedialog {
      background-color: ${surface-base.hex};
      color: ${text-primary.hex};
    }

    /* GTK .background class (used by many apps for main background) */
    .background {
      background-color: ${surface-base.hex};
      color: ${text-primary.hex};
    }

    /* Message dialog content area */
    messagedialog .dialog-vbox,
    messagedialog .message-area,
    dialog .dialog-vbox {
      background-color: ${surface-base.hex};
    }

    /* Dialog action area (button row) */
    messagedialog .dialog-action-area,
    dialog .dialog-action-area {
      background-color: ${surface-base.hex};
      border-top: 1px solid ${divider-primary.hex};
    }

    headerbar {
      background-color: ${surface-emphasis.hex};
      color: ${text-primary.hex};
      border-bottom: 1px solid ${divider-secondary.hex};
    }

    /* GTK4 specific selections */
    .view:selected,
    .view:selected:focus {
      background-color: ${accent.secondary.Lc75.hex};
      color: ${surface-base.hex};
    }

    /* ========================================================================
     * Accessibility & State Indicators
     * ======================================================================== */

    /* Focus indicators */
    *:focus {
      outline-color: ${accent.secondary.Lc75.hex};
      outline-width: 2px;
      outline-style: solid;
    }

    /* Error states */
    .error {
      color: ${accent.danger.Lc75.hex};
    }

    entry.error {
      border-color: ${accent.danger.Lc75.hex};
    }

    /* Warning states */
    .warning {
      color: ${accent.warning.Lc75.hex};
    }

    /* Success states */
    .success {
      color: ${accent.primary.Lc75.hex};
    }

    /* ========================================================================
     * Signal Design System Specific
     * ======================================================================== */

    /* Custom classes for applications that want to use Signal semantics */
    .signal-surface-base { background-color: ${surface-base.hex}; }
    .signal-surface-subtle { background-color: ${surface-subtle.hex}; }
    .signal-surface-emphasis { background-color: ${surface-emphasis.hex}; }
    .signal-text-primary { color: ${text-primary.hex}; }
    .signal-text-secondary { color: ${text-secondary.hex}; }
    .signal-text-tertiary { color: ${text-tertiary.hex}; }
    .signal-accent-focus { color: ${accent.secondary.Lc75.hex}; }
    .signal-accent-danger { color: ${accent.danger.Lc75.hex}; }
    .signal-accent-success { color: ${accent.primary.Lc75.hex}; }
    .signal-accent-warning { color: ${accent.warning.Lc75.hex}; }
    .signal-accent-info { color: ${accent.secondary.Lc75.hex}; }
    .signal-accent-special { color: ${accent.tertiary.Lc75.hex}; }
  '';

  # Index theme file
  indexTheme = ''
    [Desktop Entry]
    Type=X-GNOME-Metatheme
    Name=Signal-${lib.strings.toUpper (lib.substring 0 1 themeMode)}${lib.substring 1 (-1) themeMode}
    Comment=Signal Design System GTK theme (${themeMode} mode)
    Encoding=UTF-8

    [X-GNOME-Metatheme]
    GtkTheme=Signal-${themeMode}
    MetacityTheme=Signal-${themeMode}
    IconTheme=Adwaita
    CursorTheme=Adwaita
    ButtonLayout=close,minimize,maximize:menu
  '';

in
stdenv.mkDerivation {
  name = "signal-gtk-theme-${themeMode}";
  version = "1.0.0";

  src = ./.;

  unpackPhase = "true";

  installPhase = ''
    # Create theme directory structure
    mkdir -p $out/share/themes/Signal-${themeMode}/gtk-3.0
    mkdir -p $out/share/themes/Signal-${themeMode}/gtk-4.0

    # Install GTK3 CSS
    cat > $out/share/themes/Signal-${themeMode}/gtk-3.0/gtk.css << 'EOF'
    ${gtkCss}
    EOF

    # Install GTK4 CSS (same content, GTK4 is mostly compatible)
    cat > $out/share/themes/Signal-${themeMode}/gtk-4.0/gtk.css << 'EOF'
    ${gtkCss}
    EOF

    # Install index.theme
    cat > $out/share/themes/Signal-${themeMode}/index.theme << 'EOF'
    ${indexTheme}
    EOF

    # Create empty assets directories (for future expansion)
    mkdir -p $out/share/themes/Signal-${themeMode}/gtk-3.0/assets
    mkdir -p $out/share/themes/Signal-${themeMode}/gtk-4.0/assets
  '';

  meta = {
    description = "Signal Design System GTK theme (${themeMode} mode)";
    longDescription = ''
      A comprehensive GTK3/GTK4 theme based on Signal's OKLCH color system.
      Provides scientifically-designed colors with APCA accessibility compliance.

      Compatible with both GTK3 and GTK4 applications, including GNOME shell
      applications, GDM login screen, and system dialogs.
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
