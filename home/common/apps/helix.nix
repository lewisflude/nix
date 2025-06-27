{ lib, ... }:
let
  standards = import ../development/language-standards.nix;

  # Helper function to create indentation string
  makeIndentString = n: builtins.concatStringsSep "" (builtins.genList (_x: " ") n);
in
{
  programs.helix = {
    enable = true;
    languages = {
      language = lib.mapAttrsToList (
        name: value:
        (
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
      ) standards.languages;
    };

    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
        bufferline = "multiple";
        soft-wrap.enable = true;
      };

      editor.cursor-shape = {
        insert = "bar";
        normal = "block";
        select = "underline";
      };

      editor.indent-guides = {
        render = true;
        character = "┊";
      };

      keys.normal = {
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };

      editor.lsp = {
        display-messages = true;
        display-inlay-hints = true;
        auto-signature-help = true;
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
        ];
        mode.normal = "NORMAL";
        mode.insert = "INSERT";
        mode.select = "SELECT";
      };

      editor.whitespace = {
        render = {
          space = "all";
          tab = "all";
        };
        characters = {
          space = "·";
          nbsp = "⍽";
          tab = "→";
          newline = "⏎";
          tabpad = " ";
        };
      };

      editor.file-picker = {
        hidden = false;
        parents = true;
        ignore = true;
        git-ignore = true;
      };
    };
  };
}
