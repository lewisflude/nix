# Signal Design System Integration
# Replaces old theming system with extracted Signal module from flake
{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  # Get the old theming config to use as reference
  oldCfg = config.theming.signal;
in
{
  imports = [
    inputs.signal.homeManagerModules.default
  ];

  config = mkIf oldCfg.enable {
    # Enable Signal theme with the same settings as before
    theming.signal = {
      enable = true;
      mode = oldCfg.mode;

      # Enable applications based on old config
      ironbar = {
        enable = oldCfg.applications.ironbar.enable or false;
        profile = "relaxed"; # Default for 1440p+
      };

      gtk.enable = oldCfg.applications.gtk.enable or false;
      helix.enable = oldCfg.applications.helix.enable or false;
      fuzzel.enable = true; # Always enable fuzzel for launcher

      terminals = {
        ghostty.enable = oldCfg.applications.ghostty.enable or false;
        zellij.enable = oldCfg.applications.zellij.enable or false;
      };

      cli = {
        bat.enable = oldCfg.applications.bat.enable or false;
        fzf.enable = oldCfg.applications.fzf.enable or false;
        lazygit.enable = oldCfg.applications.lazygit.enable or false;
        yazi.enable = oldCfg.applications.yazi.enable or false;
      };

      # Preserve brand governance settings if they exist
      brandGovernance = {
        policy = oldCfg.brandGovernance.policy or "functional-override";
        decorativeBrandColors = oldCfg.brandGovernance.decorativeBrandColors or {};
        brandColors = oldCfg.brandGovernance.brandColors or {};
      };

      # Preserve variant if set
      variant = oldCfg.variant or null;
    };
  };
}
