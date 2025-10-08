{ lib, ... }:
let
  standards = import ../development/language-standards.nix;

  makeIndentString = n: builtins.concatStringsSep "" (builtins.genList (_x: " ") n);
in
{
  programs.helix = {
    enable = true;
    languages = {
      language =
        lib.mapAttrsToList
          (
            name: value: (
              {
                inherit name;
                scope = "source.${name}";
                injection-regex = name;
                file-types = value.fileTypes or [ name ];
                language-servers = [ value.lsp ];
                indent = {
                  tab-width = value.indent;
                  unit = value.unit or (makeIndentString value.indent);
                };
                auto-format = value.formatter != null;
              }
              // lib.optionalAttrs (value ? comment) {
                comment-tokens = [ value.comment ];
              }
              // lib.optionalAttrs (value.formatter != null) {
                formatter = {
                  command = value.formatter;
                };
              }
            )
          )
          standards.languages;
    };

    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
        bufferline = "multiple";
        true-color = true;
        undercurl = true;
        color-modes = true;
        scrolloff = 8;
        rulers = [
          80
          120
        ];
        completion-trigger-len = 1;
        idle-timeout = 0;
        middle-click-paste = true;
        end-of-line-diagnostics = "hint";
        soft-wrap.enable = true;
      };

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
        display-messages = true;
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

      keys.normal = {
        space = {
          space = "file_picker";
          w = ":w";
          q = ":q";
        };
        "A-," = "goto_previous_buffer";
        "A-." = "goto_next_buffer";
        "A-w" = ":buffer-close";
        "A-/" = "repeat_last_motion";
        "C-," = ":config-open";
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };

      keys.insert = {
        j = {
          k = "normal_mode";
        };
      };
    };
  };
}
