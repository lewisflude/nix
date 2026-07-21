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
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.qutebrowser.settings
# UPSTREAM SCHEMA: https://github.com/qutebrowser/qutebrowser
# SCHEMA VERSION: 3.1.0
# LAST VALIDATED: 2026-01-17
# NOTES: Qutebrowser uses Python config. Home-Manager provides settings attrset
#        that gets serialized to config.py. Colors are in the 'colors' namespace.
let
  inherit (lib) mkIf;
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
  };

  # Accent colors for various states
  accent = {
    focus = semantic.core "focus" themeMode;
    success = semantic.status "success" themeMode;
    warning = semantic.status "warning" themeMode;
    danger = semantic.status "error" themeMode;
    info = semantic.status "info" themeMode;
    tertiary = semantic.core "focus" themeMode; # Reuse focus color
  };

  # Check if qutebrowser should be themed
  shouldTheme = signalLib.shouldThemeApp "qutebrowser" [
    "browsers"
    "qutebrowser"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.qutebrowser.settings = {
      colors = {
        # Background/foreground
        webpage.bg = colors.surface-base.hex;

        # Completion widget
        completion = {
          fg = colors.text-primary.hex;
          odd.bg = colors.surface-base.hex;
          even.bg = colors.surface-base.hex;
          category = {
            fg = colors.text-primary.hex;
            bg = colors.surface-raised.hex;
            border = {
              top = colors.divider.hex;
              bottom = colors.divider.hex;
            };
          };
          item.selected = {
            fg = colors.text-primary.hex;
            bg = colors.surface-hover.hex;
            border = {
              top = accent.focus.hex;
              bottom = accent.focus.hex;
            };
          };
          match.fg = accent.focus.hex;
          scrollbar = {
            fg = colors.divider.hex;
            bg = colors.surface-base.hex;
          };
        };

        # Downloads
        downloads = {
          bar.bg = colors.surface-raised.hex;
          start = {
            fg = colors.surface-base.hex;
            bg = accent.focus.hex;
          };
          stop = {
            fg = colors.surface-base.hex;
            bg = accent.success.hex;
          };
          error.fg = accent.danger.hex;
        };

        # Hints
        hints = {
          fg = colors.surface-base.hex;
          bg = accent.warning.hex;
          match.fg = accent.focus.hex;
        };

        # Keyhints
        keyhint = {
          fg = colors.text-primary.hex;
          bg = colors.surface-raised.hex;
          suffix.fg = accent.focus.hex;
        };

        # Messages
        messages = {
          error = {
            fg = colors.surface-base.hex;
            bg = accent.danger.hex;
            border = accent.danger.hex;
          };
          warning = {
            fg = colors.surface-base.hex;
            bg = accent.warning.hex;
            border = accent.warning.hex;
          };
          info = {
            fg = colors.text-primary.hex;
            bg = colors.surface-raised.hex;
            border = colors.divider.hex;
          };
        };

        # Prompts
        prompts = {
          fg = colors.text-primary.hex;
          bg = colors.surface-raised.hex;
          border = colors.divider.hex;
          selected.bg = colors.surface-hover.hex;
        };

        # Status bar
        statusbar = {
          normal = {
            fg = colors.text-primary.hex;
            bg = colors.surface-base.hex;
          };
          insert = {
            fg = colors.surface-base.hex;
            bg = accent.success.hex;
          };
          passthrough = {
            fg = colors.surface-base.hex;
            bg = accent.focus.hex;
          };
          private = {
            fg = colors.surface-base.hex;
            bg = accent.tertiary.hex;
          };
          command = {
            fg = colors.text-primary.hex;
            bg = colors.surface-raised.hex;
            private = {
              fg = colors.text-primary.hex;
              bg = colors.surface-raised.hex;
            };
          };
          caret = {
            fg = colors.surface-base.hex;
            bg = accent.tertiary.hex;
            selection = {
              fg = colors.surface-base.hex;
              bg = accent.focus.hex;
            };
          };
          progress.bg = accent.focus.hex;
          url = {
            fg = colors.text-primary.hex;
            error.fg = accent.danger.hex;
            hover.fg = accent.focus.hex;
            success = {
              http.fg = accent.success.hex;
              https.fg = accent.success.hex;
            };
            warn.fg = accent.warning.hex;
          };
        };

        # Tabs
        tabs = {
          bar.bg = colors.surface-base.hex;
          indicator = {
            start = accent.focus.hex;
            stop = accent.success.hex;
            error = accent.danger.hex;
          };
          odd = {
            fg = colors.text-secondary.hex;
            bg = colors.surface-base.hex;
          };
          even = {
            fg = colors.text-secondary.hex;
            bg = colors.surface-base.hex;
          };
          pinned = {
            even = {
              fg = colors.text-secondary.hex;
              bg = colors.surface-raised.hex;
            };
            odd = {
              fg = colors.text-secondary.hex;
              bg = colors.surface-raised.hex;
            };
            selected = {
              even = {
                fg = colors.text-primary.hex;
                bg = colors.surface-hover.hex;
              };
              odd = {
                fg = colors.text-primary.hex;
                bg = colors.surface-hover.hex;
              };
            };
          };
          selected = {
            odd = {
              fg = colors.text-primary.hex;
              bg = colors.surface-raised.hex;
            };
            even = {
              fg = colors.text-primary.hex;
              bg = colors.surface-raised.hex;
            };
          };
        };
      };
    };
  };
}
