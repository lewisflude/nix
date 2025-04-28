{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        kamadorueda.alejandra
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        ms-vsliveshare.vsliveshare
        eamodio.gitlens
        mkhl.direnv
        tamasfe.even-better-toml
        bradlc.vscode-tailwindcss
        github.vscode-pull-request-github
        usernamehw.errorlens
        formulahendry.auto-rename-tag
        christian-kohler.path-intellisense
        streetsidesoftware.code-spell-checker
        oderwat.indent-rainbow
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
        "editor.codeActionsOnSave" = { "source.fixAll.eslint" = "always"; };
        "eslint.validate" =
          [ "javascript" "javascriptreact" "typescript" "typescriptreact" ];
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = true;
        "editor.linkedEditing" = true;
        "editor.suggestSelection" = "first";
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [ 80 120 ];
        "editor.fontLigatures" = true;
        "files.autoSave" = "onFocusChange";
        "files.trimTrailingWhitespace" = true;
        "terminal.integrated.defaultProfile.linux" = "bash";
        "workbench.editor.enablePreview" = false;
        "git.autofetch" = true;
        "git.confirmSync" = false;
      };
    };
  };
}
