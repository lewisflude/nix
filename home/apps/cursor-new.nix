# Cursor/VSCode Home-Manager Configuration
# Modular configuration split into logical components
#
# - Extensions: ./cursor/extensions.nix
# - Editor Settings: ./cursor/settings.nix  
# - AI Configuration: ./cursor/ai-settings.nix
# - Language Settings: ./cursor/language-settings.nix

{ pkgs, lib, ... }:
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
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    
    profiles.default = {
      extensions = extensions.extensions;
      userSettings = mergedSettings;
      
      # Global snippets and keybindings can be added here
      keybindings = [
        {
          key = "ctrl+shift+p";
          command = "workbench.action.showCommands";
        }
      ];
    };
  };
}