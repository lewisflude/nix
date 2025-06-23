# Cursor/VSCode Editor Settings
# Optimized for senior developers: performance, productivity, and reliability

{ pkgs, constants, ... }:
let
  inherit (constants) commonIgnores watcherIgnores;
in
{
  userSettings = {
    # ==== CORE EDITOR EXPERIENCE ====

    # Visual & Performance
    "editor.fontSize" = 14;
    "editor.lineHeight" = 1.4;
    "editor.fontLigatures" = true;
    "editor.rulers" = [ 80 120 ];
    "editor.wordWrap" = "bounded";
    "editor.wordWrapColumn" = 80;
    "editor.minimap.enabled" = false;
    "editor.smoothScrolling" = true;
    "editor.cursorBlinking" = "smooth";
    "editor.semanticHighlighting.enabled" = true;

    # Code Intelligence (Senior Dev Essentials)
    "editor.suggest.localityBonus" = true;
    "editor.suggest.shareSuggestSelections" = true;
    "editor.suggest.preview" = true;
    "editor.suggest.showSnippets" = true;
    "editor.tabCompletion" = "on";
    "editor.parameterHints.enabled" = true;
    "editor.parameterHints.cycle" = true;
    "editor.hover.delay" = 300;
    "editor.hover.sticky" = true;

    # Navigation & Multi-cursor (Senior Dev Productivity)
    "editor.gotoLocation.multipleReferences" = "peek";
    "editor.gotoLocation.multipleDefinitions" = "peek";
    "editor.multiCursorModifier" = "ctrlCmd";
    "editor.multiCursorMergeOverlapping" = true;
    "editor.find.addExtraSpaceOnTop" = false;
    "editor.find.autoFindInSelection" = "multiline";

    # Bracket & Indentation (Clean Code)
    "editor.matchBrackets" = "always";
    "editor.bracketPairColorization.enabled" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.guides.highlightActiveIndentation" = true;
    "editor.guides.indentation" = true;

    # Code Actions & Formatting (Senior Dev Standards)
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = true;
    "editor.codeActionsOnSave" = {
      "source.organizeImports" = "always";
      "source.fixAll" = "always";
    };

    # ==== FILE & WORKSPACE MANAGEMENT ====

    # File Handling (Reliability Focus)
    "files.exclude" = commonIgnores;
    "files.watcherExclude" = watcherIgnores;
    "files.autoSave" = "onFocusChange";
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "files.hotExit" = "onExit";
    "files.associations" = {
      "*.env.*" = "dotenv";
      ".env*" = "dotenv";
      "*.jsonc" = "jsonc";
      "Dockerfile.*" = "dockerfile";
    };

    # Search (Performance Optimized)
    "search.exclude" = commonIgnores;
    "search.useIgnoreFiles" = true;
    "search.useGitIgnore" = true;
    "search.smartCase" = true;
    "search.showLineNumbers" = true;
    "search.maxResults" = 20000;

    # ==== WORKBENCH OPTIMIZATION ====

    # Startup & Performance (Senior Dev Efficiency)
    "workbench.startupEditor" = "none";
    "workbench.editor.enablePreview" = false;
    "workbench.editor.highlightModifiedTabs" = true;
    "workbench.editor.limit.enabled" = true;
    "workbench.editor.limit.value" = 12;
    "workbench.commandPalette.history" = 50;

    # Theme & Layout (Clean & Professional)
    "workbench.colorTheme" = "Catppuccin Mocha";
    "workbench.iconTheme" = "catppuccin-mocha";
    "workbench.activityBar.location" = "top";
    "workbench.panel.defaultLocation" = "right";
    "workbench.statusBar.visible" = true;

    # Navigation (Senior Dev Workflow)
    "breadcrumbs.enabled" = true;
    "breadcrumbs.filePath" = "on";
    "breadcrumbs.symbolPath" = "on";
    "workbench.quickOpen.preserveInput" = true;

    # ==== EXPLORER & FILE MANAGEMENT ====

    "explorer.compactFolders" = false; # Better for large projects
    "explorer.confirmDelete" = true;
    "explorer.confirmDragAndDrop" = true;
    "explorer.fileNesting.enabled" = true;
    "explorer.fileNesting.patterns" = {
      # TypeScript/JavaScript
      "*.ts" = "$${capture}.js, $${capture}.d.ts";
      "*.js" = "$${capture}.js.map, $${capture}.min.js";
      "*.tsx" = "$${capture}.ts";
      "*.jsx" = "$${capture}.js";

      # Package Management
      "package.json" = "package-lock.json, yarn.lock, pnpm-lock.yaml, bun.lockb";
      "tsconfig.json" = "tsconfig.*.json";

      # Documentation & Config
      "readme*" = "authors, changelog*, contributing*, license*, security.md";
      ".gitignore" = ".gitattributes, .gitmodules, .gitmessage";

      # Language Specific
      "Cargo.toml" = "Cargo.lock";
      "flake.nix" = "flake.lock";
    };
    "explorer.sortOrder" = "type";
    "explorer.openEditors.visible" = 5;

    # ==== GIT INTEGRATION ====

    # Git Workflow (Senior Dev Essentials)
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.enableCommitSigning" = true;
    "git.path" = "${pkgs.git}/bin/git";
    "git.gpgPath" = "${pkgs.gnupg}/bin/gpg";
    "git.openRepositoryInParentFolders" = "always";
    "git.decorations.enabled" = true;
    "git.timeline.enabled" = true;

    # Commit Standards
    "git.inputValidation" = "always";
    "git.inputValidationLength" = 72;
    "git.inputValidationSubjectLength" = 50;
    "git.branchProtection" = [ "main" "master" "develop" ];

    # ==== TERMINAL INTEGRATION ====

    "terminal.integrated.defaultProfile.osx" = "zsh";
    "terminal.integrated.fontSize" = 13;
    "terminal.integrated.scrollback" = 10000;
    "terminal.integrated.shellIntegration.enabled" = true;
    "terminal.integrated.smoothScrolling" = true;
    "terminal.integrated.env.osx" = {
      "GPG_TTY" = "$(tty)";
    };

    # ==== DIFF & MERGE ====

    "diffEditor.renderSideBySide" = true;
    "diffEditor.ignoreTrimWhitespace" = false;
    "diffEditor.codeLens" = true;
    "merge-conflict.autoNavigateNextConflict.enabled" = true;

    # ==== CURSOR-SPECIFIC OPTIMIZATIONS ====

    # Optimize for AI assistance
    "editor.quickSuggestions" = {
      "other" = "on";
      "comments" = "off";
      "strings" = "on";
    };
    "editor.quickSuggestionsDelay" = 10;
    "editor.wordBasedSuggestions" = "matchingDocuments";
    "editor.acceptSuggestionOnCommitCharacter" = true;

    # Multi-cursor & Selection (AI-Enhanced Workflow)
    "editor.selectionHighlight" = true;
    "editor.occurrencesHighlight" = "singleFile";
    "editor.wordHighlightBackground" = "#484848";
    "editor.wordHighlightStrongBackground" = "#525252";

    # ==== PRODUCTIVITY FEATURES ====

    # Auto-save & Recovery
    "files.autoSaveDelay" = 1000;
    "editor.autoClosingBrackets" = "always";
    "editor.autoClosingOvertype" = "always";
    "editor.autoClosingQuotes" = "always";
    "editor.autoIndent" = "full";

    # Refactoring & Code Actions
    "editor.lightBulb.enabled" = true;
    "editor.codeActionWidget.includeNearbyQuickFixes" = true;
    "problems.decorations.enabled" = true;
    "problems.showCurrentInStatus" = true;

    # ==== SECURITY & PRIVACY ====

    "telemetry.telemetryLevel" = "off";
    "security.workspace.trust.enabled" = false;
    "extensions.ignoreRecommendations" = true;
    "extensions.autoCheckUpdates" = false;

    # ==== KEYBINDINGS INTEGRATION ====

    # Prepare for custom keybindings
    "keyboard.dispatch" = "keyCode";
    "editor.multiCursorLimit" = 10000;
    "workbench.list.multiSelectModifier" = "ctrlCmd";

    # ==== ACCESSIBILITY & UX ====

    # Disable annoying sounds (Senior Dev Preference)
    "accessibility.signals.lineHasBreakpoint" = { "sound" = "off"; };
    "accessibility.signals.lineHasError" = { "sound" = "off"; };
    "accessibility.signals.lineHasWarning" = { "sound" = "off"; };

    # Smooth interactions
    "workbench.list.smoothScrolling" = true;
    "workbench.tree.renderIndentGuides" = "always";
    "workbench.tree.indent" = 8;
  };
}
