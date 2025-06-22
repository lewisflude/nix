{
  programs.helix = {
    enable = true;
    languages = {
      language = [
        {
          name = "nix";
          scope = "source.nix";
          injection-regex = "nix";
          file-types = [ "nix" ];
          comment-token = "#";
          language-servers = [ "nil" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          formatter = {
            command = "nixpkgs-fmt";
          };
          auto-format = true;
        }
        {
          name = "typescript";
          scope = "source.ts";
          injection-regex = "ts";
          file-types = [
            "ts"
            "tsx"
          ];
          comment-token = "//";
          language-servers = [ "typescript-language-server" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          formatter = {
            command = "biome";
          };
          auto-format = true;
        }
        {
          name = "javascript";
          scope = "source.js";
          injection-regex = "js";
          file-types = [
            "js"
            "jsx"
          ];
          comment-token = "//";
          language-servers = [ "typescript-language-server" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          formatter = {
            command = "biome";
          };
          auto-format = true;
        }
        {
          name = "json";
          scope = "source.json";
          injection-regex = "json";
          file-types = [ "json" ];
          language-servers = [ "vscode-langservers-extracted" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          formatter = {
            command = "biome";
          };
          auto-format = true;
        }
        {
          name = "yaml";
          scope = "source.yaml";
          injection-regex = "yaml";
          file-types = [
            "yaml"
            "yml"
          ];
          language-servers = [ "yaml-language-server" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          formatter = {
            command = "biome";
          };
          auto-format = true;
        }
        {
          name = "markdown";
          scope = "source.md";
          injection-regex = "markdown";
          file-types = [
            "md"
            "markdown"
          ];
          language-servers = [ "marksman" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          formatter = {
            command = "biome";
          };
          auto-format = true;
        }
        {
          name = "rust";
          scope = "source.rust";
          injection-regex = "rust";
          file-types = [ "rs" ];
          language-servers = [ "rust-analyzer" ];
          indent = {
            tab-width = 4;
            unit = "    ";
          };
          formatter = {
            command = "rustfmt";
          };
          auto-format = true;
        }
        {
          name = "python";
          scope = "source.python";
          injection-regex = "python";
          file-types = [ "py" ];
          language-servers = [ "pyright" ];
          indent = {
            tab-width = 4;
            unit = "    ";
          };
          formatter = {
            command = "black";
          };
          auto-format = true;
        }
      ];
    };

    settings = {
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
        render = "all";
        characters = {
          space = "·";
          nbsp = "⍽";
          tab = "→";
          newline = "⏎";
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
