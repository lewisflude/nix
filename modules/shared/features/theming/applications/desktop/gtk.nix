{
  config,
  lib,
  pkgs,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  inherit (themeContext) theme;

  # Determine if we're on Linux
  inherit (pkgs.stdenv) isLinux;

  # Generate GTK CSS overrides
  generateGtkCss =
    palette:
    let
      inherit (palette) colors;
    in
    ''
      /* Signal Color Theme - GTK Overrides */

      /* Base color definitions */
      @define-color theme_bg_color ${colors."surface-base".hex};
      @define-color theme_fg_color ${colors."text-primary".hex};
      @define-color theme_base_color ${colors."surface-base".hex};
      @define-color theme_text_color ${colors."text-primary".hex};
      @define-color theme_selected_bg_color ${colors."accent-primary".hex};
      @define-color theme_selected_fg_color ${colors."surface-base".hex};

      /* Insensitive (disabled) states */
      @define-color insensitive_bg_color ${colors."surface-subtle".hex};
      @define-color insensitive_fg_color ${colors."text-tertiary".hex};
      @define-color insensitive_base_color ${colors."surface-subtle".hex};

      /* Borders */
      @define-color borders ${colors."divider-primary".hex};
      @define-color unfocused_borders ${colors."divider-primary".hex};
      @define-color divider_color ${colors."divider-primary".hex};

      /* State colors */
      @define-color warning_color ${colors."accent-warning".hex};
      @define-color error_color ${colors."accent-danger".hex};
      @define-color success_color ${colors."accent-primary".hex};

      /* Window decorations */
      @define-color wm_title ${colors."text-primary".hex};
      @define-color wm_unfocused_title ${colors."text-secondary".hex};
      @define-color wm_bg ${colors."surface-base".hex};
      @define-color wm_border ${colors."divider-secondary".hex};

      /* Additional semantic colors */
      @define-color accent_bg_color ${colors."accent-primary".hex};
      @define-color accent_fg_color ${colors."surface-base".hex};
      @define-color accent_color ${colors."accent-primary".hex};
      @define-color destructive_bg_color ${colors."accent-danger".hex};
      @define-color destructive_fg_color ${colors."surface-base".hex};
      @define-color destructive_color ${colors."accent-danger".hex};

      /* View colors */
      @define-color view_bg_color ${colors."surface-base".hex};
      @define-color view_fg_color ${colors."text-primary".hex};

      /* Hover states */
      @define-color theme_hover_color ${colors."surface-subtle".hex};

      /* Card backgrounds */
      @define-color card_bg_color ${colors."surface-subtle".hex};
      @define-color card_fg_color ${colors."text-primary".hex};

      /* Dialog backgrounds */
      @define-color dialog_bg_color ${colors."surface-base".hex};
      @define-color dialog_fg_color ${colors."text-primary".hex};

      /* Popover backgrounds */
      @define-color popover_bg_color ${colors."surface-subtle".hex};
      @define-color popover_fg_color ${colors."text-primary".hex};

      /* Sidebar colors */
      @define-color sidebar_bg_color ${colors."surface-base".hex};
      @define-color sidebar_fg_color ${colors."text-primary".hex};
      @define-color sidebar_backdrop_color ${colors."surface-subtle".hex};

      /* Header bar */
      @define-color headerbar_bg_color ${colors."surface-base".hex};
      @define-color headerbar_fg_color ${colors."text-primary".hex};
      @define-color headerbar_border_color ${colors."divider-primary".hex};
      @define-color headerbar_backdrop_color ${colors."surface-subtle".hex};

      /* Custom styles for better theming */
      window {
        background-color: @theme_bg_color;
        color: @theme_fg_color;
      }

      .background {
        background-color: @theme_bg_color;
        color: @theme_fg_color;
      }

      /* Dialog windows - ensure authentication dialogs use theme colors */
      dialog {
        background-color: @dialog_bg_color;
        color: @dialog_fg_color;
      }

      dialog window {
        background-color: @dialog_bg_color;
        color: @dialog_fg_color;
      }

      /* Entry fields (including password inputs) */
      entry {
        background-color: @view_bg_color;
        color: @view_fg_color;
        border: 1px solid @borders;
        border-radius: 6px;
        padding: 6px 10px;
        min-height: 32px;
      }

      entry:focus {
        border-color: @accent_color;
        outline: 1px solid @accent_color;
        outline-offset: -1px;
      }

      entry:disabled {
        background-color: @insensitive_bg_color;
        color: @insensitive_fg_color;
        border-color: @borders;
      }

      /* Ensure polkit and pinentry dialogs are styled */
      window.background {
        background-color: @dialog_bg_color;
        color: @dialog_fg_color;
      }

      /* Polkit authentication dialog styling - comprehensive selectors */
      /* polkit-gnome uses various class names and structures */
      /* Note: GTK CSS doesn't support :has() or complex attribute selectors,
         so we use broad selectors that will catch polkit dialogs */
      .polkit-dialog,
      .polkit-dialog window,
      .polkit-dialog .background,
      window.polkit-dialog,
      window.polkit-dialog window,
      window.polkit-dialog .background,
      /* Target the actual authentication agent dialogs */
      .polkit-agent-dialog,
      .polkit-agent-dialog window,
      .polkit-agent-dialog .background,
      window.polkit-agent-dialog,
      /* Target common polkit dialog structures */
      .polkit-dialog-widget,
      .polkit-dialog-widget window,
      .polkit-dialog-widget .background {
        background-color: @dialog_bg_color;
        color: @dialog_fg_color;
      }

      /* Style password entry fields in polkit dialogs */
      /* These selectors will apply to all entry fields, which is fine */
      .polkit-dialog entry,
      .polkit-agent-dialog entry,
      .polkit-dialog-widget entry,
      window.polkit-dialog entry,
      window.polkit-agent-dialog entry {
        background-color: @view_bg_color;
        color: @view_fg_color;
        border: 1px solid @borders;
        border-radius: 6px;
        padding: 6px 10px;
        min-height: 32px;
      }

      .polkit-dialog entry:focus,
      .polkit-agent-dialog entry:focus,
      .polkit-dialog-widget entry:focus,
      window.polkit-dialog entry:focus,
      window.polkit-agent-dialog entry:focus {
        border-color: @accent_color;
        outline: 1px solid @accent_color;
        outline-offset: -1px;
      }

      /* Labels in polkit dialogs */
      .polkit-dialog label,
      .polkit-agent-dialog label,
      .polkit-dialog-widget label,
      window.polkit-dialog label,
      window.polkit-agent-dialog label {
        color: @dialog_fg_color;
      }

      /* Buttons in polkit dialogs */
      .polkit-dialog button,
      .polkit-agent-dialog button,
      .polkit-dialog-widget button,
      window.polkit-dialog button,
      window.polkit-agent-dialog button {
        background-color: @card_bg_color;
        color: @dialog_fg_color;
        border: 1px solid @borders;
        border-radius: 6px;
        padding: 6px 12px;
        min-height: 32px;
      }

      .polkit-dialog button:hover,
      .polkit-agent-dialog button:hover,
      .polkit-dialog-widget button:hover,
      window.polkit-dialog button:hover,
      window.polkit-agent-dialog button:hover {
        background-color: @divider_color;
        border-color: @accent_color;
      }

      .polkit-dialog button:active,
      .polkit-agent-dialog button:active,
      .polkit-dialog-widget button:active,
      window.polkit-dialog button:active,
      window.polkit-agent-dialog button:active {
        background-color: @accent_color;
        color: @accent_fg_color;
      }

      .polkit-dialog button.suggested-action,
      .polkit-agent-dialog button.suggested-action,
      .polkit-dialog-widget button.suggested-action,
      window.polkit-dialog button.suggested-action,
      window.polkit-agent-dialog button.suggested-action {
        background-color: @accent_bg_color;
        color: @accent_fg_color;
        border-color: @accent_bg_color;
      }

      /* Pinentry dialog styling */
      .pinentry-dialog,
      .pinentry-dialog window,
      .pinentry-dialog .background {
        background-color: @dialog_bg_color;
        color: @dialog_fg_color;
      }

      /* Labels in dialogs */
      dialog label,
      dialog .label {
        color: @dialog_fg_color;
      }

      /* Buttons in dialogs */
      dialog button {
        background-color: @card_bg_color;
        color: @dialog_fg_color;
        border: 1px solid @borders;
        border-radius: 6px;
        padding: 6px 12px;
        min-height: 32px;
      }

      dialog button:hover {
        background-color: @divider_color;
        border-color: @accent_color;
      }

      dialog button:active {
        background-color: @accent_color;
        color: @accent_fg_color;
      }

      dialog button.suggested-action {
        background-color: @accent_bg_color;
        color: @accent_fg_color;
        border-color: @accent_bg_color;
      }

      dialog button.suggested-action:hover {
        background-color: @accent_color;
      }

      /* Ensure all windows inherit dialog colors when they're dialogs */
      /* Non-CSD windows (like polkit dialogs) will use dialog colors */
      window:not(.csd) {
        background-color: @dialog_bg_color;
        color: @dialog_fg_color;
      }

      /* Note: GTK CSS doesn't support attribute selectors like entry[visibility="password"]
         Password entry styling is handled by the general entry rules above */

      /* Context menus and popup menus - fix double background issue */
      /* According to GTK4 docs: popover > contents.background > menu
         We need to make the outer popover transparent and style the contents */

      /* Make the outer popover window transparent (no padding/border) */
      popover.menu {
        background: transparent;
        padding: 0;
        margin: 0;
        border: none;
        box-shadow: none;
      }

      /* Style the contents node which contains the menu */
      popover.menu contents,
      popover.menu > contents {
        background-color: @popover_bg_color;
        color: @popover_fg_color;
        border: 1px solid @borders;
        border-radius: 8px;
        padding: 4px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
      }

      /* Additional menu styling for compatibility */
      menu,
      .menu {
        background-color: @popover_bg_color;
        color: @popover_fg_color;
        padding: 4px;
      }

      /* Menu items */
      menuitem,
      .menuitem,
      menu menuitem,
      .menu menuitem {
        background-color: transparent;
        color: @popover_fg_color;
        border-radius: 4px;
        padding: 6px 12px;
        margin: 2px;
      }

      menuitem:hover,
      .menuitem:hover,
      menu menuitem:hover,
      .menu menuitem:hover {
        background-color: @theme_hover_color;
        color: @popover_fg_color;
      }

      menuitem:disabled,
      .menuitem:disabled {
        color: @insensitive_fg_color;
      }

      /* Separators in menus */
      separator,
      .separator,
      menu separator,
      .menu separator {
        background-color: @borders;
        min-height: 1px;
        margin: 4px 0;
      }

      /* Non-menu popovers (tooltips, date pickers, etc.) */
      /* Style the contents node for proper rendering */
      popover:not(.menu) {
        background: transparent;
        padding: 0;
        border: none;
      }

      popover:not(.menu) contents {
        background-color: @popover_bg_color;
        color: @popover_fg_color;
        border: 1px solid @borders;
        border-radius: 8px;
        padding: 8px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
      }

      /* Note: Ironbar styling is handled by ironbar-home.nix */
      /* which generates ~/.config/ironbar/style.css with Signal theme colors */
    '';
in
{
  config = mkIf (cfg.enable && cfg.applications.gtk.enable && theme != null && isLinux) {
    # Set libadwaita color scheme via environment variable
    # This is the proper way for GTK4/libadwaita applications
    home.sessionVariables = {
      ADW_COLOR_SCHEME = if cfg.mode == "dark" then "prefer-dark" else "prefer-light";
    };

    gtk = {
      enable = true;

      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = cfg.mode == "dark";
        };
      };

      gtk4 = {
        extraConfig = {
          # Don't use gtk-application-prefer-dark-theme for GTK4/libadwaita
          # It will use ADW_COLOR_SCHEME from the environment instead
        };
      };
    };

    # Configure GNOME desktop interface preferences via dconf
    # This is used by xdg-desktop-portal-gnome and Flatpak apps
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = if cfg.mode == "dark" then "prefer-dark" else "prefer-light";
        gtk-theme = lib.mkDefault (cfg.gtkTheme or "Adwaita");
      };
    };

    # Generate GTK3 CSS override
    xdg.configFile."gtk-3.0/gtk.css".text = generateGtkCss theme;

    # Generate GTK4 CSS override
    xdg.configFile."gtk-4.0/gtk.css".text = generateGtkCss theme;
  };
}
