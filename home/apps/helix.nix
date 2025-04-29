{
  programs.helix = {
    enable = true;

    settings = {

      programs.helix = {
        enable = true;
        defaultEditor = true;
        settings = {
          editor = {
            line-number = "relative";
            lsp.display-messages = true;
          };
        };
        languages = {
          language = [{
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
            formatter = { command = "nixpkgs-fmt"; };
            auto-format = true;
          }];
        };
      };

      keys.normal = {
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
        esc = [ "collapse_selection" "keep_primary_selection" ];
      };

      editor.lsp = {
        display-messages = true;
        display-inlay-hints = true;
        auto-signature-help = true;
      };

      editor.statusline = {
        left = [ "mode" "spinner" "file-name" "file-modification-indicator" ];
        center = [ ];
        right = [ "diagnostics" "selections" "position" "file-encoding" ];
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
