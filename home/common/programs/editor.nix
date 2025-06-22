{ pkgs, cursor, ... }: {
  home.sessionVariables = {
    EDITOR = "hx";
    SUDO_EDITOR = "hx";
  };
  home.packages = with pkgs; [
    nil
    nixpkgs-fmt
    helix
    vscode
    nodePackages.eslint
    nodePackages.prettier
    claude-code
  ];
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
      ];
    };
  };
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        ms-vsliveshare.vsliveshare
        tamasfe.even-better-toml
        bradlc.vscode-tailwindcss
        github.vscode-pull-request-github
        pkief.material-icon-theme
        usernamehw.errorlens
        gruntfuggly.todo-tree
        christian-kohler.path-intellisense
        visualstudioexptteam.vscodeintellicode
      ];
      userSettings = {
        "workbench.colorTheme" = "Catppuccin Mocha";
        "catppuccin.accentColor" = "mauve";
        "catppuccin.boldKeywords" = true;
        "catppuccin.italicComments" = true;
        "catppuccin.italicKeywords" = true;
        "catppuccin.workbenchMode" = "default";
        "catppuccin.bracketMode" = "rainbow";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = "nixpkgs-fmt";
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
        "prettier.singleQuote" = true;
        "prettier.tabWidth" = 2;
        "editor.codeActionsOnSave" = {
          "source.fixAll.eslint" = "always";
        };
        "eslint.validate" = [
          "javascript"
          "javascriptreact"
          "typescript"
          "typescriptreact"
        ];
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = true;
        "editor.linkedEditing" = true;
        "editor.suggestSelection" = "first";
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [ 80 100 120 ];
        "editor.fontLigatures" = true;
        "files.autoSave" = "onFocusChange";
        "files.trimTrailingWhitespace" = true;
        "terminal.integrated.defaultProfile.linux" = "bash";
        "workbench.editor.enablePreview" = false;
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "editor.fontFamily" = "'Iosevka Nerd Font', monospace";
        "editor.fontSize" = 14;
        "editor.lineHeight" = 1.5;
        "editor.minimap.enabled" = true;
        "editor.minimap.maxColumn" = 120;
        "editor.minimap.scale" = 2;
        "workbench.editor.wrapTabs" = false;
        "workbench.editor.scrollToSwitchTabs" = true;
        "window.zoomLevel" = 0;
        "editor.wordWrap" = "bounded";
        "editor.wordWrapColumn" = 120;
        "workbench.sideBar.location" = "right";
        "workbench.editor.showTabs" = "multiple";
        "workbench.editor.enablePreviewFromQuickOpen" = false;
      };
    };
  };
}
