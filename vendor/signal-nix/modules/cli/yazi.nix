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
# HOME-MANAGER MODULE: programs.yazi.theme
# UPSTREAM SCHEMA: https://yazi-rs.github.io/docs/configuration/theme/
# SCHEMA VERSION: 0.2.4
# LAST VALIDATED: 2026-01-17
# NOTES: Home-Manager provides structured theme option that serializes to TOML.
#        The theme attrset structure matches yazi's theme.toml schema exactly.
let
  inherit (lib) mkIf removePrefix;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Helper to get hex without # prefix
  hexRaw = color: removePrefix "#" color;

  # Helper to get semantic color hex
  c = name: hexRaw (semantic.resolve name themeMode).hex;
  cCore = name: hexRaw (semantic.core name themeMode).hex;
  cUI = name: hexRaw (semantic.ui name themeMode).hex;
  cText = name: hexRaw (semantic.text name themeMode).hex;
  cVCS = name: hexRaw (semantic.vcs name themeMode).hex;
  cStatus = name: hexRaw (semantic.status name themeMode).hex;

  # Helper functions to reduce repetitive color mappings
  # These create consistent attribute structures for yazi theme
  mkColorPair = fg: bg: {
    fg = fg;
    bg = bg;
  };

  mkMarker = color: mkColorPair color color;

  mkModeStyle = fg: bg: {
    fg = fg;
    bg = bg;
    bold = true;
  };

  # Check if yazi should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "yazi" [
    "cli"
    "yazi"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.yazi.theme = {
      # App - Overall terminal background
      app = {
        overall = {
          bg = cUI "panel-background";
        };
      };

      # Indicator - Indicator bars for different panes
      indicator = {
        parent = {
          fg = cUI "panel-border";
        };
        current = {
          fg = cVCS "modified";
        };
        preview = {
          fg = cUI "element-active";
        };
      };

      # Tabs - Tab styling
      tabs = {
        active = {
          fg = cText "primary";
          bg = cUI "panel-background";
          bold = true;
        };
        inactive = {
          fg = cText "secondary";
          bg = cUI "panel-border";
        };
        sep_inner = {
          open = "[";
          close = "]";
        };
        sep_outer = {
          open = "";
          close = "";
        };
      };

      # Mode - Mode indicators (normal, select, unset)
      mode = {
        normal_main = mkModeStyle (cUI "panel-background") (cVCS "modified");
        normal_alt = mkColorPair (cVCS "modified") (cUI "element-hover");
        select_main = mkModeStyle (cUI "panel-background") (cVCS "added");
        select_alt = mkColorPair (cVCS "added") (cUI "element-hover");
        unset_main = mkModeStyle (cUI "panel-background") (cStatus "warning");
        unset_alt = mkColorPair (cStatus "warning") (cUI "element-hover");
      };

      # Manager (file list) colors
      manager = {
        cwd = {
          fg = cVCS "modified";
        };
        hovered = {
          fg = cText "primary";
          bg = cUI "element-hover";
        };
        preview_hovered = {
          fg = cText "primary";
          bg = cUI "panel-border";
        };
        find_keyword = {
          fg = cStatus "warning";
          bold = true;
        };
        find_position = {
          fg = cVCS "modified";
          bg = "reset";
          italic = true;
        };
        marker_copied = mkMarker (cVCS "added");
        marker_cut = mkMarker (cVCS "deleted");
        marker_marked = mkMarker (cVCS "modified");
        marker_selected = mkMarker (cStatus "warning");
        tab_active = {
          fg = cText "primary";
          bg = cUI "panel-background";
        };
        tab_inactive = {
          fg = cText "secondary";
          bg = cUI "panel-border";
        };
        tab_width = 1;
        border_symbol = "│";
        border_style = {
          fg = cUI "panel-border";
        };
      };

      # Status line
      status = {
        separator_open = "";
        separator_close = "";
        separator_style = {
          fg = cUI "element-hover";
          bg = cUI "element-hover";
        };
        mode_normal = mkModeStyle (cUI "panel-background") (cVCS "modified");
        mode_select = mkModeStyle (cUI "panel-background") (cVCS "added");
        mode_unset = mkModeStyle (cUI "panel-background") (cStatus "warning");
        progress_label = {
          fg = cText "primary";
          bold = true;
        };
        progress_normal = {
          fg = cVCS "modified";
          bg = cUI "element-hover";
        };
        progress_error = {
          fg = cStatus "error";
          bg = cUI "element-hover";
        };
        permissions_t = {
          fg = cVCS "added";
        };
        permissions_r = {
          fg = cStatus "warning";
        };
        permissions_w = {
          fg = cStatus "error";
        };
        permissions_x = {
          fg = cVCS "added";
        };
        permissions_s = {
          fg = cStatus "info";
        };
      };

      # Input line
      input = {
        border = {
          fg = cVCS "modified";
        };
        title = { };
        value = {
          fg = cText "primary";
        };
        selected = {
          bg = cUI "element-hover";
        };
      };

      # Select component
      select = {
        border = {
          fg = cVCS "modified";
        };
        active = {
          fg = cVCS "added";
          bold = true;
        };
        inactive = {
          fg = cText "secondary";
        };
      };

      # Tasks
      tasks = {
        border = {
          fg = cVCS "modified";
        };
        title = { };
        hovered = {
          fg = cVCS "added";
          underline = true;
        };
      };

      # Which (keybinding help)
      which = {
        mask = {
          bg = cUI "panel-background";
        };
        cand = {
          fg = cVCS "modified";
        };
        rest = {
          fg = cText "secondary";
        };
        desc = {
          fg = cText "primary";
        };
        separator = "  ";
        separator_style = {
          fg = cUI "element-active";
        };
      };

      # Help
      help = {
        on = {
          fg = cVCS "added";
        };
        run = {
          fg = cVCS "modified";
        };
        desc = {
          fg = cText "secondary";
        };
        hovered = {
          bg = cUI "element-hover";
          bold = true;
        };
        footer = {
          fg = cText "secondary";
          bg = cUI "panel-background";
        };
      };

      # Confirm - Confirmation dialogs
      confirm = {
        border = {
          fg = cVCS "modified";
        };
        title = {
          fg = cText "primary";
          bold = true;
        };
        body = {
          fg = cText "primary";
        };
        list = {
          fg = cText "secondary";
        };
        btn_yes = {
          fg = cUI "panel-background";
          bg = cVCS "added";
          bold = true;
        };
        btn_no = {
          fg = cUI "panel-background";
          bg = cVCS "deleted";
          bold = true;
        };
        btn_labels = [
          "Yes"
          "No"
        ];
      };

      # Spot - Spotlight/table view
      spot = {
        border = {
          fg = cVCS "modified";
        };
        title = {
          fg = cText "primary";
          bold = true;
        };
        tbl_col = {
          fg = cVCS "modified";
          bg = cUI "element-hover";
        };
        tbl_cell = {
          fg = cText "primary";
          bg = cUI "panel-border";
        };
      };

      # Notify - Notification styling
      notify = {
        title_info = {
          fg = cStatus "info";
          bold = true;
        };
        title_warn = {
          fg = cStatus "warning";
          bold = true;
        };
        title_error = {
          fg = cStatus "error";
          bold = true;
        };
      };

      # Pick - Picker/selection UI
      pick = {
        border = {
          fg = cVCS "modified";
        };
        active = {
          fg = cVCS "added";
          bold = true;
        };
        inactive = {
          fg = cText "secondary";
        };
      };

      # Cmp - Completion menu
      cmp = {
        border = {
          fg = cVCS "modified";
        };
        active = {
          fg = cText "primary";
          bg = cUI "element-hover";
          bold = true;
        };
        inactive = {
          fg = cText "secondary";
        };
        icon_file = "";
        icon_folder = "";
        icon_command = "";
      };

      # File-specific colors
      filetype = {
        rules = [
          # Directories
          {
            mime = "inode/directory";
            fg = cVCS "modified";
            bold = true;
          }
          # Executables
          {
            name = "*";
            is = "exec";
            fg = cVCS "added";
          }
          # Links
          {
            name = "*";
            is = "link";
            fg = cVCS "modified";
          }
          # Orphan links
          {
            name = "*";
            is = "orphan";
            fg = cStatus "error";
          }
          # Documents
          {
            mime = "text/*";
            fg = cText "primary";
          }
          # Images
          {
            mime = "image/*";
            fg = cStatus "warning";
          }
          # Videos
          {
            mime = "video/*";
            fg = cStatus "info";
          }
          # Audio
          {
            mime = "audio/*";
            fg = cVCS "modified";
          }
          # Archives
          {
            mime = "application/*zip";
            fg = cStatus "error";
          }
          {
            mime = "application/*tar";
            fg = cStatus "error";
          }
          {
            mime = "application/*rar";
            fg = cStatus "error";
          }
        ];
      };
    };
  };
}
