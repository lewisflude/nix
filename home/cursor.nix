{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        editorconfig.editorconfig
      ];

      userSettings = {
        # Editor settings
        "editor.fontFamily" = "JetBrains Mono";
        "editor.fontSize" = 14;
        "editor.fontLigatures" = true;
        "editor.lineHeight" = 1.5;
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [ 80 100 ];
        "editor.smoothScrolling" = true;
        "editor.tabSize" = 2;
        "editor.wordWrap" = "on";
        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = true;
        "editor.defaultFormatter" = "editor.action.formatDocument";

        # Terminal settings
        "terminal.integrated.fontFamily" = "JetBrains Mono";
        "terminal.integrated.fontSize" = 14;
        "terminal.integrated.defaultProfile.osx" = "zsh";

        # Workbench settings
        "workbench.colorTheme" = "Default Dark+";
        "workbench.startupEditor" = "newUntitledFile";
        "workbench.editor.enablePreview" = false;

        # File settings
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;

        # Git settings
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "git.autofetch" = true;

        # Language specific settings
        "[nix]" = {
          "editor.formatOnSave" = true;
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
      };

      keybindings = [
        {
          key = "cmd+k cmd+s";
          command = "workbench.action.openGlobalKeybindings";
        }
        {
          key = "cmd+k cmd+t";
          command = "workbench.action.terminal.toggleTerminal";
        }
        {
          key = "cmd+k cmd+f";
          command = "editor.action.formatDocument";
        }
      ];
    };
  };
}
