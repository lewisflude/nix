{
  pkgs,
  constants,
  ...
}: let
  inherit (constants) commonIgnores watcherIgnores;
in {
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
    "files.autoSaveDelay" = 5000;
    "editor.quickSuggestionsDelay" = 100;
    "editor.acceptSuggestionOnEnter" = "smart";
    "files.watcherExclude" = watcherIgnores;
    "search.followSymlinks" = false;
    "search.maxResults" = 10000;
    "extensions.autoUpdate" = false;
    "extensions.autoCheckUpdates" = false;
    "extensions.ignoreRecommendations" = true;
    "window.restoreWindows" = "none";
    "window.enableMenuBarMnemonics" = false;
    "workbench.reduceMotion" = "on";
    "workbench.enableExperiments" = false;
    "git.autoRepositoryDetection" = "subFolders";
    "git.scanRepositories" = [];
    "typescript.preferences.includePackageJsonAutoImports" = "on";
    "typescript.suggest.autoImports" = true;
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
    "terminal.integrated.scrollback" = 100000;
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
