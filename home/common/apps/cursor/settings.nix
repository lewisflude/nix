# Cursor/VSCode Editor Settings
# Optimized for senior developers: performance, productivity, and reliability

{ pkgs, constants, ... }:
let
  inherit (constants) commonIgnores watcherIgnores;
in
{
  userSettings = {
    "editor.fontSize" = 14;
    "editor.lineHeight" = 1.5;
    "editor.fontLigatures" = true;
    "editor.fontFamily" = "Iosevka Nerd Font, Iosevka";
    "editor.rulers" = [
      80
      120
    ];
    "editor.wordWrap" = "bounded";
    "editor.wordWrapColumn" = 80;
    "editor.matchBrackets" = "always";
    "editor.bracketPairColorization.enabled" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.guides.highlightActiveIndentation" = true;
    "editor.guides.indentation" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = true;

    "editor.semanticHighlighting.enabled" = true;
    "terminal.integrated.minimumContrastRatio" = 1;
    "window.titleBarStyle" = "custom";

    # ==== CRASH PREVENTION & STABILITY SETTINGS ====
    # Memory management and performance optimizations
    "files.autoSaveDelay" = 5000; # Increase autosave delay to reduce I/O stress
    "editor.quickSuggestionsDelay" = 100; # Reduce suggestion frequency
    "editor.acceptSuggestionOnEnter" = "smart"; # Prevent accidental completions

    # File watcher limits to prevent system overload
    "files.watcherExclude" = watcherIgnores;
    "search.followSymlinks" = false; # Prevent infinite loops in search
    "search.maxResults" = 10000; # Reduce from 20000 to prevent memory issues

    # Extension stability settings
    "extensions.autoUpdate" = false; # Prevent automatic updates that can cause instability
    "extensions.autoCheckUpdates" = false;
    "extensions.ignoreRecommendations" = true;

    # Window and rendering stability
    "window.restoreWindows" = "none"; # Prevent crash loops on startup
    "window.enableMenuBarMnemonics" = false; # Reduce menu-related crashes
    "workbench.reduceMotion" = "on"; # Reduce animations that can cause GPU issues
    "workbench.enableExperiments" = false; # Disable experimental features

    # Git performance and stability
    "git.autoRepositoryDetection" = "subFolders"; # Re-enabled with scope to prevent excessive scanning
    "git.scanRepositories" = [ ]; # Disable automatic repository scanning

    # Language server stability - Re-enable useful TypeScript features
    "typescript.preferences.includePackageJsonAutoImports" = "on"; # Re-enabled for better DX
    "typescript.suggest.autoImports" = true; # Re-enabled - very helpful for productivity

    # Chat and AI stability settings
    "workbench.experimental.settingsProfiles.enabled" = false;
    "workbench.experimental.cloudChanges.enabled" = false;

    "files.exclude" = commonIgnores;
    "files.autoSave" = "onFocusChange";
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "files.hotExit" = "onExit";

    "search.useIgnoreFiles" = true;
    "search.useGitIgnore" = true;
    "search.smartCase" = true;
    "search.showLineNumbers" = true;

    "workbench.colorTheme" = "Catppuccin Mocha";

    "explorer.compactFolders" = false;
    "explorer.confirmDelete" = true;
    "explorer.confirmDragAndDrop" = true;
    "explorer.fileNesting.enabled" = true;
    "explorer.fileNesting.patterns" = {
      "*.ts" = "$${capture}.js, $${capture}.d.ts";
      "*.js" = "$${capture}.js.map, $${capture}.min.js";
      "*.tsx" = "$${capture}.ts";
      "*.jsx" = "$${capture}.js";
      "package.json" = "package-lock.json, yarn.lock, pnpm-lock.yaml, bun.lockb";
      "tsconfig.json" = "tsconfig.*.json";
      "readme*" = "authors, changelog*, contributing*, license*, security.md";
      ".gitignore" = ".gitattributes, .gitmodules, .gitmessage";
      "Cargo.toml" = "Cargo.lock";
      "flake.nix" = "flake.lock";
    };

    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.enableCommitSigning" = true;
    "git.path" = "${pkgs.git}/bin/git";
    "git.gpgPath" = "${pkgs.gnupg}/bin/gpg";
    "git.openRepositoryInParentFolders" = "always";
    "git.decorations.enabled" = true;
    "git.timeline.enabled" = true;
    "git.inputValidation" = true;
    "git.inputValidationLength" = 72;
    "git.inputValidationSubjectLength" = 50;
    "git.branchProtection" = [
      "main"
      "master"
      "develop"
    ];

    "terminal.integrated.defaultProfile.osx" = "zsh";
    "terminal.integrated.defaultProfile.linux" = "zsh";
    "terminal.integrated.fontSize" = 14;
    "terminal.integrated.scrollback" = 10000;
    "terminal.integrated.shellIntegration.enabled" = true;
    "terminal.integrated.env.linux" = {
      "GPG_TTY" = "$(tty)";
    };
    "terminal.integrated.env.osx" = {
      "GPG_TTY" = "$(tty)";
    };

    "telemetry.telemetryLevel" = "off";
    "security.workspace.trust.enabled" = false;
  };
}
