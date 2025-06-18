# Cursor/VSCode Editor Settings
# Core editor configuration and behavior

{ ... }:
let
  # DRY ignore patterns
  commonIgnores = {
    "**/.DS_Store" = true;
    "**/.direnv" = true;
    "**/.git" = true;
  };
  watcherIgnores = commonIgnores // {
    "**/.git/objects/**" = true;
    "**/.git/subtree-cache/**" = true;
    "**/.git/index.lock" = true;
    "**/node_modules/**" = true;
    "**/.next/**" = true;
    "**/dist/**" = true;
    "**/build/**" = true;
    "**/.cache/**" = true;
  };
in
{
  userSettings = {
    # Editor Core Settings (optimized for half-screen)
    "editor.rulers" = [ 80 ];
    "editor.fontSize" = 14;
    "editor.lineHeight" = 1.4;
    "editor.wordWrap" = "bounded";
    "editor.wordWrapColumn" = 80;
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = true;
    "editor.minimap.enabled" = false;
    "editor.scrollbar.vertical" = "auto";
    "editor.scrollbar.horizontal" = "auto";
    "editor.occurrencesHighlight" = "off";
    "editor.matchBrackets" = "near";
    "editor.quickSuggestions" = {
      "other" = true;
      "comments" = true;
      "strings" = true;
    };
    "editor.codeActionsOnSave" = {
      "source.organizeImports" = "always";
      "source.fixAll" = "always";
      "source.fixAll.biome" = "always";
    };

    # File Management
    "files.exclude" = commonIgnores;
    "files.readonlyInclude" = {
      "**/.direnv/**" = true;
    };
    "files.watcherExclude" = watcherIgnores;
    "files.autoSave" = "onFocusChange";

    # Search Configuration
    "search.exclude" = commonIgnores;
    "search.useIgnoreFiles" = true;

    # Workbench (optimized for narrow screens)
    "workbench.startupEditor" = "none";
    "workbench.editor.enablePreview" = false;
    "workbench.colorTheme" = "Catppuccin Mocha";
    "workbench.iconTheme" = "catppuccin-mocha";
    "workbench.sideBar.location" = "left";
    "workbench.activityBar.visible" = false;
    "workbench.editor.showTabs" = "multiple";
    "workbench.editor.tabSizing" = "shrink";
    "workbench.sideBar.width" = 200;
    "workbench.panel.defaultLocation" = "right";

    # Auto-hide sidebar on narrow screens
    "workbench.statusBar.visible" = true;
    "breadcrumbs.enabled" = false;

    # Security & Telemetry
    "telemetry.telemetryLevel" = "off";
    "security.workspace.trust.enabled" = false;

    # Terminal (optimized for half-screen)
    "terminal.integrated.defaultProfile.osx" = "zsh";
    "terminal.integrated.fontSize" = 13;
    "terminal.integrated.lineHeight" = 1.2;
    "terminal.integrated.minimumContrastRatio" = 4.5;

    # Explorer
    "explorer.compactFolders" = true;
    "explorer.fileNesting.enabled" = true;
    "explorer.openEditors.visible" = 0;

    # Extension Recommendations (reduce sidebar clutter)
    "extensions.showRecommendationsOnlyOnDemand" = true;
    "extensions.ignoreRecommendations" = true;

    # Git
    "git.autofetch" = true;
    "git.confirmSync" = false;
  };
}
