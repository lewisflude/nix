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
    # Editor Core Settings
    "editor.rulers" = [ 80 120 ];
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = true;
    "editor.quickSuggestions" = {
      "other" = true;
      "comments" = true;
      "strings" = true;
    };
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
    
    # Workbench
    "workbench.startupEditor" = "none";
    "workbench.editor.enablePreview" = false;
    
    # Security & Telemetry
    "telemetry.telemetryLevel" = "off";
    "security.workspace.trust.enabled" = false;
    
    # Terminal
    "terminal.integrated.defaultProfile.osx" = "zsh";
    
    # Git
    "git.autofetch" = true;
    "git.confirmSync" = false;
  };
}