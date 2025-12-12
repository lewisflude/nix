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
      # Universal Access - disable transparency for better performance
      # DISABLED: Causes activation failure on some macOS versions
      # Moved to activation script below with error handling
      # universalaccess = {
      #   reduceTransparency = true;
      #   reduceMotion = true;
      # };

      # Additional NSGlobalDomain performance settings
      # Note: Some settings are in CustomUserPreferences as they're not in nix-darwin yet
      NSGlobalDomain = {
        # These options are already set in system-preferences.nix
        # Keeping this section for future additions
      };

      # Custom settings via activation scripts
      CustomUserPreferences = {
        # NSGlobalDomain performance settings
        "NSGlobalDomain" = {
          NSAutomaticWindowAnimationsEnabled = false;
          NSDisableAutomaticTermination = true;
          NSQuitAlwaysKeepsWindows = false;
        };

        # Finder performance
        "com.apple.finder" = {
          # Disable animations
          DisableAllAnimations = true;
          # Show all files faster
          AppleShowAllFiles = false;
        };

        # Dock performance
        "com.apple.dock" = {
          # No animation when opening applications
          launchanim = false;
          # Remove auto-hide delay
          autohide-delay = 0.0;
          # Make hidden apps transparent in Dock
          showhidden = true;
        };

        # Safari performance
        # DISABLED: Safari preferences are in a sandboxed container and can't be written via CustomUserPreferences
        # Moved to activation script below with error handling
        # "com.apple.Safari" = {
        #   # Disable thumbnail cache for Top Sites
        #   DebugSnapshotsUpdatePolicy = 2;
        #   # Enable debug menu
        #   IncludeInternalDebugMenu = true;
        # };

        # Mail performance
        # DISABLED: Mail preferences are in a sandboxed container and can't be written via CustomUserPreferences
        # Moved to activation script below with error handling
        # "com.apple.mail" = {
        #   # Disable inline attachments
        #   DisableInlineAttachmentViewing = true;
        #   # Disable send and reply animations
        #   DisableReplyAnimations = true;
        #   DisableSendAnimations = true;
        # };

        # Mission Control performance
        "com.apple.dock" = {
          # Speed up Mission Control animations
          expose-animation-duration = 0.1;
          # Don't automatically rearrange Spaces
          mru-spaces = false;
        };

        # System performance
        "com.apple.systempreferences" = {
          NSQuitAlwaysKeepsWindows = false;
        };

        # Window Manager performance
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = false;
          StandardHideDesktopIcons = false;
          HideDesktop = false;
          StageManagerHideWidgets = false;
          AutoHide = false;
        };

        # Disable Dashboard
        "com.apple.dashboard" = {
          "mcx-disabled" = true;
        };
      };
    };

    # System-wide performance tweaks via activation scripts
    system.activationScripts.performance.text = ''
      # Disable sudden motion sensor (not needed on SSDs, saves CPU cycles)
      pmset -a sms 0 2>/dev/null || true

      # Disable hibernation (speeds up sleep/wake)
      pmset -a hibernatemode 0 2>/dev/null || true

      # Remove sleep image file to save space
      rm -f /var/vm/sleepimage 2>/dev/null || true

      # Disable the sound effects on boot
      nvram SystemAudioVolume=" " 2>/dev/null || true

      # Expand save panel by default
      defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
      defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

      # Expand print panel by default
      defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
      defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

      # Automatically quit printer app once the print jobs complete
      defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

      # Disable the crash reporter
      defaults write com.apple.CrashReporter DialogType -string "none"

      # Disable Notification Center and remove the menu bar icon
      launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2>/dev/null || true

      # Disable smart quotes as they're annoying when typing code
      defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

      # Disable smart dashes as they're annoying when typing code
      defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

      # Increase window resize speed for Cocoa applications
      defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

      # Disable automatic app termination
      defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

      # Speed up wake from sleep
      pmset -a standbydelay 86400 2>/dev/null || true

      # Universal Access - disable transparency and motion for better performance
      # Use activation script with error handling since system.defaults.universalaccess
      # can fail on some macOS versions
      defaults write com.apple.universalaccess reduceTransparency -bool true 2>/dev/null || true
      defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null || true

      # Safari performance settings
      # Safari preferences are in a sandboxed container, so we need to write directly
      # Use error handling since these may fail if Safari is running or container doesn't exist
      defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2 2>/dev/null || true
      defaults write com.apple.Safari IncludeInternalDebugMenu -bool true 2>/dev/null || true

      # Mail performance settings
      # Mail preferences are in a sandboxed container, so we need to write directly
      # Use error handling since these may fail if Mail is running or container doesn't exist
      defaults write com.apple.mail DisableInlineAttachmentViewing -bool true 2>/dev/null || true
      defaults write com.apple.mail DisableReplyAnimations -bool true 2>/dev/null || true
      defaults write com.apple.mail DisableSendAnimations -bool true 2>/dev/null || true
    '';
  };
}
