{ pkgs, ... }: {
  home.packages = with pkgs; [
    code-cursor
    nodejs_20
    nodePackages.pnpm
    nodePackages.typescript
    zellij
    ripgrep
    fd
    fzf
    docker
    docker-compose
    direnv
    nix-direnv
    playwright
  ];

  programs = {
    vscode = { enable = true; };
    helix = {
      enable = true;

      settings = {
        theme = "catppuccin_mocha";

        editor = {
          line-number = "relative";
          mouse = false;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          indent-guides.render = true;
          true-color = true;
          bufferline = "always";
          soft-wrap.enable = true;
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
  };
}
