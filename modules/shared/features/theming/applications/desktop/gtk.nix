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

      /* Authentication dialog specific styling */
      .polkit-dialog,
      .polkit-dialog window,
      .polkit-dialog .background {
        background-color: @dialog_bg_color;
        color: @dialog_fg_color;
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
      window:not(.csd) {
        background-color: @dialog_bg_color;
        color: @dialog_fg_color;
      }
    '';
in
{
  config = mkIf (cfg.enable && cfg.applications.gtk.enable && theme != null && isLinux) {
    gtk = {
      enable = true;

      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = cfg.mode == "dark";
        };
      };

      gtk4 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = cfg.mode == "dark";
        };
      };
    };

    # Generate GTK3 CSS override
    xdg.configFile."gtk-3.0/gtk.css".text = generateGtkCss theme;

    # Generate GTK4 CSS override
    xdg.configFile."gtk-4.0/gtk.css".text = generateGtkCss theme;
  };
}
