# Cursor/VSCode Editor Settings
# Core editor configuration and behavior

{ pkgs, constants, ... }:
let
  inherit (constants) commonIgnores watcherIgnores;
in
{
  userSettings = {
    # Editor Core Settings
    "editor.rulers" = [ 80 ];
    "editor.fontSize" = 14;
    "editor.lineHeight" = 1.4;
    "editor.wordWrap" = "bounded";
    "editor.wordWrapColumn" = 80;
    "editor.minimap.enabled" = false;
    "editor.occurrencesHighlight" = "off";
    "editor.matchBrackets" = "near";

    # Code Actions & Formatting (biome-specific settings in language-settings.nix)
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = true;
    "editor.codeActionsOnSave" = {
      "source.organizeImports" = "always";
      "source.fixAll" = "always";
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

    # Workbench (optimized for productivity)
    "workbench.startupEditor" = "none";
    "workbench.editor.enablePreview" = false;
    "workbench.colorTheme" = "Catppuccin Mocha";
    "workbench.iconTheme" = "catppuccin-mocha";
    "workbench.activityBar.visible" = false;
    "workbench.editor.tabSizing" = "shrink";
    "workbench.panel.defaultLocation" = "right";
    "breadcrumbs.enabled" = false;

    # Security & Privacy
    "telemetry.telemetryLevel" = "off";
    "security.workspace.trust.enabled" = false;

    # Terminal
    "terminal.integrated.defaultProfile.osx" = "zsh";
    "terminal.integrated.fontSize" = 13;
    "terminal.integrated.lineHeight" = 1.2;
    "terminal.integrated.minimumContrastRatio" = 4.5;
    "terminal.integrated.env.osx" = {
      "GPG_TTY" = "$(tty)";
    };

    # Explorer
    "explorer.compactFolders" = true;
    "explorer.fileNesting.enabled" = true;
    "explorer.openEditors.visible" = 0;

    # Extensions
    "extensions.showRecommendationsOnlyOnDemand" = true;
    "extensions.ignoreRecommendations" = true;

    # Git (removed hardcoded signing key)
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.enableCommitSigning" = true;
    "git.path" = "${pkgs.git}/bin/git";
    "git.useEditorAsCommitInput" = false;
    "git.gpgPath" = "${pkgs.gnupg}/bin/gpg";
  };
}
