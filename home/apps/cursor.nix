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
  devExperience = with pkgs.vscode-extensions; [
    usernamehw.errorlens # Inline error/warning display
    yoavbls.pretty-ts-errors # Human-readable TypeScript errors
    redhat.vscode-yaml # YAML validation & IntelliSense
  ];
  languages = with pkgs.vscode-extensions; [
    ms-python.python # Python language support
    ms-python.pylint # Python linting
    golang.go # Go language support
    timonwong.shellcheck # Shell script linting
    ms-vscode-remote.remote-containers # Docker development
    davidanson.vscode-markdownlint # Markdown linting
  ];
  # DRY ignore patterns
  commonIgnores = {
    "**/.DS_Store" = true;
    "**/.direnv" = true;
    "**/.git" = true;
  };
  watcherIgnores = commonIgnores // {
    "**/.git/objects/**" = true;
    "**/.git/subtree-cache/**" = true;
    "**/.hg/store/**" = true;
    "**/nix/store/**" = true;
  };
  # Extra config for bulky/complex JSON
  extraConfig = {
    "editor.rulers" = [
      80
      120
    ];
    "editor.quickSuggestions" = {
      "other" = true;
      "comments" = true;
      "strings" = true;
    };
    "editor.codeActionsOnSave" = {
      "source.organizeImports" = "always";
      "source.fixAll" = "always";
    };
    "files.readonlyInclude" = {
      "/nix/store/**" = true;
    };
    "files.watcherExclude" = watcherIgnores;
  };
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    profiles.default = {
      extensions = coreLangs ++ tools ++ gitTools ++ devExperience ++ languages;
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
        "cursor.beta.completeWithSpeedReads" = true;
        "cursor.beta.codeSuggestions" = true;
        "cursor.beta.predictiveSelection" = true;
        "cursor.models.default" = "gpt-4o";
        "cursor.models.enabled" = [
          "gpt-4o"
          "claude-3.5-sonnet"
          "gemini-2.5-pro-max"
          "o3"
        ];
        "cursor.rules.user" = [
          "Prefer concise, well-documented, idiomatic code in all languages."
          "Follow existing code patterns and conventions in the project."
          "Use TypeScript strict mode and proper type annotations."
          "Optimize for readability and maintainability over cleverness."
        ];

        # Context Optimization
        "cursor.context.maxTokens" = 8000;
        "cursor.context.includeCurrentFile" = true;
        "cursor.context.smartSelection" = true;

        # AI Completion Tuning
        "cursor.completions.multilineThreshold" = 3;
        "cursor.completions.ghostText" = true;
        "cursor.completions.debounceDelay" = 150;

        "cursorTab.autoImport" = true;
        "cursorTab.suggestionsInComments" = true;

        # Editor UX
        "editor.bracketPairColorization.enabled" = true;
        "editor.inlineSuggest.enabled" = true;
        "editor.linkedEditing" = true;
        "editor.minimap.enabled" = false;
        "editor.semanticHighlighting.enabled" = true;
        "editor.showFoldingControls" = "always";
        "editor.smoothScrolling" = true;
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
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };

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
        # CSS/SCSS
        "[css]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.formatOnSave" = true;
        };
        "[scss]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.formatOnSave" = true;
        };
        "[less]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.formatOnSave" = true;
        };
        # Rust
        "[rust]" = {
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          "editor.formatOnSave" = true;
        };
        "rust-analyzer.checkOnSave.command" = "clippy";

        # Python
        "[python]" = {
          "editor.defaultFormatter" = "ms-python.black-formatter";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.organizeImports" = "always";
          };
        };
        "python.defaultInterpreterPath" = "python3";
        "python.linting.enabled" = true;
        "python.linting.pylintEnabled" = true;

        # Go
        "[go]" = {
          "editor.defaultFormatter" = "golang.go";
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.organizeImports" = "always";
          };
        };
        "go.formatTool" = "goimports";
        "go.lintTool" = "golangci-lint";

        # Markdown
        "[markdown]" = {
          "editor.defaultFormatter" = "davidanson.vscode-markdownlint";
          "editor.formatOnSave" = true;
          "editor.wordWrap" = "on";
        };

        # Shell
        "[shellscript]" = {
          "editor.defaultFormatter" = "timonwong.shellcheck";
        };

        # TypeScript
        "typescript.preferences.renameShorthandProperties" = false;

        # Performance
        "files.maxMemoryForLargeFilesMB" = 4096;

        # Editor Performance
        "editor.acceptSuggestionOnEnter" = "smart";
        "editor.suggest.localityBonus" = true;
        "editor.suggest.shareSuggestSelections" = false;
        "editor.renderWhitespace" = "boundary";
        "editor.renderControlCharacters" = false;

        # Memory & Tab Management
        "workbench.editor.limit.enabled" = true;
        "workbench.editor.limit.value" = 15;
        "workbench.editor.limit.perEditorGroup" = true;

        # File System Performance
        "search.useIgnoreFiles" = true;
        "search.useGlobalIgnoreFiles" = true;
        "files.hotExit" = "onExitAndWindowClose";

        # Security
        "security.workspace.trust.enabled" = true;

        # Telemetry
        "telemetry.telemetryLevel" = "off";
        "circleci.hostUrl" = "https://circleci.com";

        # Workbench
        "workbench.editor.enablePreview" = false;

        # Git
        "git.autofetch" = false;

        # Extensions
        "extensions.autoUpdate" = false;
      } // extraConfig;
    };
  };
}
