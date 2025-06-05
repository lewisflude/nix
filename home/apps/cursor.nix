# Cursor/VSCode Home-Manager Configuration
#
# - Maintained for reproducible, high-performance, and secure development
# - To update: edit this file and run `darwin-rebuild switch` or `home-manager switch`
# - To add extensions: add to the extension groups below
# - To add settings: add to the userSettings block, grouped and alphabetized
# - Review every few months for new features and to prune unused settings/extensions
#
# For project-specific rules, use .cursorrules in your repo.

{ pkgs, ... }:
let
  # Extension groups
  coreLangs = with pkgs.vscode-extensions; [
    jnoortheen.nix-ide
    rust-lang.rust-analyzer
  ];
  tools = with pkgs.vscode-extensions; [
    mkhl.direnv
    bradlc.vscode-tailwindcss
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    biomejs.biome
  ];
  gitTools = with pkgs.vscode-extensions; [
    eamodio.gitlens
    github.vscode-pull-request-github
  ];
  # DRY ignore patterns
  commonIgnores = {
    "**/.DS_Store" = true;
    "**/.direnv" = true;
    "**/.git" = true;
    "**/node_modules" = true;
  };
  watcherIgnores = commonIgnores // {
    "**/.git/objects/**" = true;
    "**/.git/subtree-cache/**" = true;
    "**/.hg/store/**" = true;
    "**/nix/store/**" = true;
  };
  # Extra config for bulky/complex JSON
  extraConfig = {
    "editor.rulers" = [ 80 120 ];
    "editor.quickSuggestions" = {
      "other" = true;
      "comments" = true;
      "strings" = true;
    };
    "editor.codeActionsOnSave" = {
      "source.organizeImports" = "always";
      "source.fixAll" = "always";
    };
    "files.readonlyInclude" = { "/nix/store/**" = true; };
    "files.watcherExclude" = watcherIgnores;
    "search.exclude" = {
      "**/bower_components" = true;
      "**/node_modules" = true;
      "**/*.code-search" = true;
    };
  };
in {
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    profiles.default = {
      extensions = coreLangs ++ tools ++ gitTools;
      userSettings = {
        # Accessibility
        "editor.accessibilitySupport" = "on";

        # Cursor AI/Features (grouped, alphabetized)
        "agent.dotFilesProtection" = true;
        "agent.outsideWorkspaceProtection" = true;
        "chat.autoAcceptDiffs" = true;
        "chat.autoApplyToFilesOutsideContextInManualMode" = true;
        "chat.autoRefresh" = true;
        "chat.autoScrollToBottom" = true;
        "chat.iterateOnLints" = true;
        "chat.webSearchTool" = true;
        "cursor.beta.notepads" = true;
        "cursor.beta.updateFrequency" = "standard";
        "cursor.models.default" = "gpt-4o";
        "cursor.models.enabled" = [
          "gpt-4o"
          "claude-3.5-sonnet"
          "claude-3.7-sonnet"
          "claude-3.7-sonnet-max"
          "gemini-2.5-pro-exp-03-25"
          "gemini-2.5-pro-max"
          "o3"
          "o4-mini"
        ];
        "cursor.rules.user" = [
          "Prefer concise, well-documented, idiomatic code in all languages."
        ];
        "cursorTab.autoImport" = true;
        "cursorTab.suggestionsInComments" = true;

        # Editor UX
        "editor.inlineSuggest.enabled" = true;
        "editor.suggest.preview" = true;

        # File handling
        "editor.formatOnSave" = true;
        "files.autoSave" = "onFocusChange";
        "files.eol" = "\n";
        "files.exclude" = commonIgnores;
        "files.insertFinalNewline" = true;
        "files.readonlyFromPermissions" = true;
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;

        # Nix-specific override
        "[nix]" = { "editor.defaultFormatter" = "jnoortheen.nix-ide"; };

        # TypeScript/JavaScript
        "[typescript]" = {
          "editor.defaultFormatter" = "biomejs.biome";
          "editor.formatOnSave" = true;
        };
        "[javascript]" = {
          "editor.defaultFormatter" = "biomejs.biome";
          "editor.formatOnSave" = true;
        };
        "[typescriptreact]" = {
          "editor.defaultFormatter" = "biomejs.biome";
          "editor.formatOnSave" = true;
        };
        "[javascriptreact]" = {
          "editor.defaultFormatter" = "biomejs.biome";
          "editor.formatOnSave" = true;
        };
        "[json]" = {
          "editor.defaultFormatter" = "biomejs.biome";
          "editor.formatOnSave" = true;
        };
        "[jsonc]" = {
          "editor.defaultFormatter" = "biomejs.biome";
          "editor.formatOnSave" = true;
        };
        # Rust
        "[rust]" = {
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          "editor.formatOnSave" = true;
        };
        "rust-analyzer.checkOnSave.command" = "clippy";

        # Performance
        "files.maxMemoryForLargeFilesMB" = 4096;

        # Security
        "security.workspace.trust.enabled" = true;

        # Telemetry
        "telemetry.telemetryLevel" = "off";
        "circleci.hostUrl" = "https://circleci.com";
      } // extraConfig;
    };
  };
}
