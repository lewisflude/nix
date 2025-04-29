{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Core language support
        jnoortheen.nix-ide
        rust-lang.rust-analyzer

        # Essential tools
        mkhl.direnv
        bradlc.vscode-tailwindcss
        github.vscode-pull-request-github

        # Git integration
        eamodio.gitlens
      ];
      userSettings = {
        # Theme settings
        "workbench.colorTheme" = "Catppuccin Mocha";
        "catppuccin.accentColor" = "mauve";
        "catppuccin.boldKeywords" = true;
        "catppuccin.italicComments" = true;
        "catppuccin.italicKeywords" = true;
        "catppuccin.workbenchMode" = "default";
        "catppuccin.bracketMode" = "rainbow";

        # Nix settings
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = "nixpkgs-fmt";
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.formatOnSave" = false;
        };

        # File handling settings
        "files.autoSave" = "onFocusChange";
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "files.eol" = "\n";

        # Read-only file handling
        "files.readonlyInclude" = {
          "/nix/store/**" = true;
        };
        "files.readonlyFromPermissions" = true;

        # File exclusions
        "files.exclude" = {
          "**/.git" = true;
          "**/.DS_Store" = true;
          "**/node_modules" = true;
          "**/.direnv" = true;
        };

        # Files to not format
        "files.watcherExclude" = {
          "**/.git/objects/**" = true;
          "**/.git/subtree-cache/**" = true;
          "**/node_modules/**" = true;
          "**/.hg/store/**" = true;
          "**/nix/store/**" = true;
        };

        # TypeScript/JavaScript settings
        "[typescript]" = {
          "editor.formatOnSave" = true;
        };
        "[javascript]" = {
          "editor.formatOnSave" = true;
        };
        "[typescriptreact]" = {
          "editor.formatOnSave" = true;
        };
        "[javascriptreact]" = {
          "editor.formatOnSave" = true;
        };

        # Rust settings
        "[rust]" = {
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          "editor.formatOnSave" = true;
        };
        "rust-analyzer.checkOnSave.command" = "clippy";

        # General formatting settings
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "always";
          "source.fixAll" = "always";
        };

        # Enhanced editor settings
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = true;
        "editor.linkedEditing" = true;
        "editor.suggestSelection" = "first";
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [80 120];
        "editor.fontLigatures" = true;
        "editor.fontSize" = 16;
        "editor.lineHeight" = 1.5;
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.smoothScrolling" = true;
        "editor.minimap.enabled" = true;
        "editor.minimap.renderCharacters" = false;
        "editor.wordWrap" = "on";
        "editor.wordWrapColumn" = 120;
        "editor.multiCursorModifier" = "alt";
        "editor.acceptSuggestionOnEnter" = "on";
        "editor.quickSuggestions" = {
          "other" = true;
          "comments" = true;
          "strings" = true;
        };

        # Terminal settings
        "terminal.integrated.defaultProfile.linux" = "bash";
        "terminal.integrated.fontSize" = 14;
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "terminal.integrated.cursorBlinking" = true;
        "terminal.integrated.cursorStyle" = "line";

        # Workbench settings
        "workbench.editor.enablePreview" = false;
        "workbench.startupEditor" = "newUntitledFile";
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.editor.highlightModifiedTabs" = true;
        "workbench.editor.limit.enabled" = true;
        "workbench.editor.limit.value" = 10;

        # Git settings
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;
        "gitlens.codeLens.enabled" = true;
        "gitlens.currentLine.enabled" = true;
        "gitlens.hovers.currentLine.over" = "line";

        # Search settings
        "search.exclude" = {
          "**/node_modules" = true;
          "**/bower_components" = true;
          "**/*.code-search" = true;
        };
        "search.followSymlinks" = false;
        "search.useIgnoreFiles" = true;
      };
    };
  };
}
