{
  lib,
  config,
  ...
}:
let
  cfg = config.host.features.performance;
in
{
  options.host.features.performance = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable macOS performance optimizations";
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults = {
      CustomUserPreferences = {
        "NSGlobalDomain" = {
          NSAutomaticWindowAnimationsEnabled = false;
          NSDisableAutomaticTermination = true;
        };
        "com.apple.finder".DisableAllAnimations = true;
      };
    };

    system.activationScripts.performance.text = ''
      # Disable sudden motion sensor (unnecessary on SSDs, saves CPU)
      pmset -a sms 0 2>/dev/null || true

      # Disable hibernation (speeds up sleep/wake on modern Macs)
      pmset -a hibernatemode 0 2>/dev/null || true

      # Reduce transparency and motion for better performance
      defaults write com.apple.universalaccess reduceTransparency -bool true 2>/dev/null || true
      defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null || true
    '';
  };
}
