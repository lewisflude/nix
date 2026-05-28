# Helix editor configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.helix
_: {
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix = {
        enable = true;
        extraPackages = [
          pkgs.nixd
          pkgs.yaml-language-server
          pkgs.taplo
          pkgs.nixfmt
          pkgs.yamlfmt
        ];
        languages.language = [
          {
            name = "nix";
            language-servers = [ "nixd" ];
            auto-format = true;
          }
          {
            name = "yaml";
            auto-format = true;
          }
          {
            name = "toml";
            auto-format = true;
          }
        ];

        settings = {
          editor = {
            line-number = "relative";
            cursorline = true;
            bufferline = "multiple";
            true-color = true;
            undercurl = true;
            clipboard-provider = "termcode";
            color-modes = true;
            scrolloff = 8;
            rulers = [
              80
              120
            ];
            completion-trigger-len = 1;
            idle-timeout = 50;
            end-of-line-diagnostics = "hint";
            soft-wrap.enable = true;
            popup-border = "all";
          };
          editor.smart-tab.enable = true;
          editor.cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          editor.indent-guides = {
            render = true;
            character = "╎";
          };
          editor.inline-diagnostics = {
            cursor-line = "error";
            other-lines = "disable";
          };
          editor.lsp = {
            display-inlay-hints = true;
            auto-signature-help = false;
          };
          editor.statusline = {
            left = [
              "mode"
              "spinner"
              "file-name"
              "file-modification-indicator"
            ];
            center = [ ];
            right = [
              "diagnostics"
              "selections"
              "position"
              "file-encoding"
              "file-type"
            ];
            mode = {
              normal = "NORMAL";
              insert = "INSERT";
              select = "SELECT";
            };
          };
          editor.whitespace = {
            render = {
              space = "none";
              tab = "all";
              newline = "none";
            };
            characters = {
              tab = "→";
              tabpad = " ";
            };
          };
          editor.file-picker = {
            hidden = false;
            parents = true;
            ignore = true;
            git-ignore = true;
          };
          keys.insert.j.k = "normal_mode";
          keys.normal = {
            "A-," = "goto_previous_buffer";
            "A-." = "goto_next_buffer";
            "A-w" = ":buffer-close";
            "A-/" = "repeat_last_motion";
            "C-," = ":config-open";
            esc = [
              "collapse_selection"
              "keep_primary_selection"
            ];
            space = {
              space = "file_picker";
              w = ":w";
              q = ":q";
            };
          };
        };
      };
    };
}
