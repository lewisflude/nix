{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf removePrefix;
  cfg = config.theming.signal;
  inherit (themeContext) theme;

  # Helper to get hex without # prefix
  hexRaw = color: removePrefix "#" color.hex;
in
{
  config = mkIf (cfg.enable && cfg.applications.yazi.enable && theme != null) {
    programs.yazi.theme = {
      # Manager (file list) colors
      manager = {
        cwd = {
          fg = hexRaw theme.colors."accent-focus";
        };
        hovered = {
          fg = hexRaw theme.colors."text-primary";
          bg = hexRaw theme.colors."surface-emphasis";
        };
        preview_hovered = {
          fg = hexRaw theme.colors."text-primary";
          bg = hexRaw theme.colors."surface-subtle";
        };
        find_keyword = {
          fg = hexRaw theme.colors."accent-warning";
          bold = true;
        };
        find_position = {
          fg = hexRaw theme.colors."accent-info";
          bg = "reset";
          italic = true;
        };
        marker_copied = {
          fg = hexRaw theme.colors."accent-primary";
          bg = hexRaw theme.colors."accent-primary";
        };
        marker_cut = {
          fg = hexRaw theme.colors."accent-danger";
          bg = hexRaw theme.colors."accent-danger";
        };
        marker_marked = {
          fg = hexRaw theme.colors."accent-focus";
          bg = hexRaw theme.colors."accent-focus";
        };
        marker_selected = {
          fg = hexRaw theme.colors."accent-warning";
          bg = hexRaw theme.colors."accent-warning";
        };
        tab_active = {
          fg = hexRaw theme.colors."text-primary";
          bg = hexRaw theme.colors."surface-base";
        };
        tab_inactive = {
          fg = hexRaw theme.colors."text-secondary";
          bg = hexRaw theme.colors."surface-subtle";
        };
        tab_width = 1;
        border_symbol = "│";
        border_style = {
          fg = hexRaw theme.colors."divider-primary";
        };
      };

      # Status line
      status = {
        separator_open = "";
        separator_close = "";
        separator_style = {
          fg = hexRaw theme.colors."surface-emphasis";
          bg = hexRaw theme.colors."surface-emphasis";
        };
        mode_normal = {
          fg = hexRaw theme.colors."surface-base";
          bg = hexRaw theme.colors."accent-focus";
          bold = true;
        };
        mode_select = {
          fg = hexRaw theme.colors."surface-base";
          bg = hexRaw theme.colors."accent-primary";
          bold = true;
        };
        mode_unset = {
          fg = hexRaw theme.colors."surface-base";
          bg = hexRaw theme.colors."accent-warning";
          bold = true;
        };
        progress_label = {
          fg = hexRaw theme.colors."text-primary";
          bold = true;
        };
        progress_normal = {
          fg = hexRaw theme.colors."accent-focus";
          bg = hexRaw theme.colors."surface-emphasis";
        };
        progress_error = {
          fg = hexRaw theme.colors."accent-danger";
          bg = hexRaw theme.colors."surface-emphasis";
        };
        permissions_t = {
          fg = hexRaw theme.colors."accent-primary";
        };
        permissions_r = {
          fg = hexRaw theme.colors."accent-warning";
        };
        permissions_w = {
          fg = hexRaw theme.colors."accent-danger";
        };
        permissions_x = {
          fg = hexRaw theme.colors."accent-primary";
        };
        permissions_s = {
          fg = hexRaw theme.colors."accent-special";
        };
      };

      # Input line
      input = {
        border = {
          fg = hexRaw theme.colors."accent-focus";
        };
        title = { };
        value = {
          fg = hexRaw theme.colors."text-primary";
        };
        selected = {
          bg = hexRaw theme.colors."surface-emphasis";
        };
      };

      # Select component
      select = {
        border = {
          fg = hexRaw theme.colors."accent-focus";
        };
        active = {
          fg = hexRaw theme.colors."accent-primary";
          bold = true;
        };
        inactive = {
          fg = hexRaw theme.colors."text-secondary";
        };
      };

      # Tasks
      tasks = {
        border = {
          fg = hexRaw theme.colors."accent-focus";
        };
        title = { };
        hovered = {
          fg = hexRaw theme.colors."accent-primary";
          underline = true;
        };
      };

      # Which (keybinding help)
      which = {
        mask = {
          bg = hexRaw theme.colors."surface-base";
        };
        cand = {
          fg = hexRaw theme.colors."accent-info";
        };
        rest = {
          fg = hexRaw theme.colors."text-secondary";
        };
        desc = {
          fg = hexRaw theme.colors."text-primary";
        };
        separator = "  ";
        separator_style = {
          fg = hexRaw theme.colors."divider-secondary";
        };
      };

      # Help
      help = {
        on = {
          fg = hexRaw theme.colors."accent-primary";
        };
        run = {
          fg = hexRaw theme.colors."accent-info";
        };
        desc = {
          fg = hexRaw theme.colors."text-secondary";
        };
        hovered = {
          bg = hexRaw theme.colors."surface-emphasis";
          bold = true;
        };
        footer = {
          fg = hexRaw theme.colors."text-secondary";
          bg = hexRaw theme.colors."surface-base";
        };
      };

      # File-specific colors
      filetype = {
        rules = [
          # Directories
          {
            mime = "inode/directory";
            fg = hexRaw theme.colors."accent-focus";
            bold = true;
          }
          # Executables
          {
            name = "*";
            is = "exec";
            fg = hexRaw theme.colors."accent-primary";
          }
          # Links
          {
            name = "*";
            is = "link";
            fg = hexRaw theme.colors."accent-info";
          }
          # Orphan links
          {
            name = "*";
            is = "orphan";
            fg = hexRaw theme.colors."accent-danger";
          }
          # Documents
          {
            mime = "text/*";
            fg = hexRaw theme.colors."text-primary";
          }
          # Images
          {
            mime = "image/*";
            fg = hexRaw theme.colors."accent-warning";
          }
          # Videos
          {
            mime = "video/*";
            fg = hexRaw theme.colors."accent-special";
          }
          # Audio
          {
            mime = "audio/*";
            fg = hexRaw theme.colors."accent-info";
          }
          # Archives
          {
            mime = "application/*zip";
            fg = hexRaw theme.colors."accent-danger";
          }
          {
            mime = "application/*tar";
            fg = hexRaw theme.colors."accent-danger";
          }
          {
            mime = "application/*rar";
            fg = hexRaw theme.colors."accent-danger";
          }
        ];
      };
    };
  };
}
