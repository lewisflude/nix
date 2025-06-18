# Cursor/VSCode Home-Manager Configuration
# Modular configuration split into logical components
#
# - Extensions: ./cursor/extensions.nix
# - Editor Settings: ./cursor/settings.nix  
# - AI Configuration: ./cursor/ai-settings.nix
# - Language Settings: ./cursor/language-settings.nix

{ pkgs, lib, config, ... }:
let
  extensions = import ./cursor/extensions.nix { inherit pkgs; };
  settings = import ./cursor/settings.nix { };
  aiSettings = import ./cursor/ai-settings.nix { };
  languageSettings = import ./cursor/language-settings.nix { };
  
  # Merge all settings together
  mergedSettings = lib.recursiveUpdate 
    (lib.recursiveUpdate settings.userSettings aiSettings.userSettings)
    languageSettings.userSettings;
in
{
  # Configure for Cursor (which is a VSCode fork)
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    
    # Use Cursor-specific directories
    userSettings = mergedSettings;
    extensions = extensions.extensions;
    keybindings = [
      {
        key = "ctrl+shift+p";
        command = "workbench.action.showCommands";
      }
      {
        key = "cmd+b";
        command = "workbench.action.toggleSidebarVisibility";
      }
      {
        key = "cmd+j";
        command = "workbench.action.togglePanel";
      }
    ];
  };

  # Note: code-cursor package manages its own configuration
  # No symlink activation needed since it's a native Cursor installation
}