{
  lib,
  config,
  ...
}: let
  cfg = config.host.features.systemPreferences;
in {
  options.host.features.systemPreferences = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable enhanced macOS system preferences";
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults = {
      NSGlobalDomain = {
        # Window behavior optimizations
        NSAutomaticWindowAnimationsEnabled = false; # Disable window animations for speed
        NSWindowResizeTime = 0.001; # Faster window resizing
        NSWindowShouldDragOnGesture = true; # Drag windows from anywhere (Linux-style)

        # Save and print panels
        NSNavPanelExpandedStateForSaveMode = true; # Expand save panel by default
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true; # Expand print panel
        PMPrintingExpandedStateForPrint2 = true;

        # Document handling
        NSDocumentSaveNewDocumentsToCloud = false; # Save to disk by default, not iCloud
        AppleWindowTabbingMode = "always"; # Always use tabs for documents

        # UI improvements
        AppleShowScrollBars = "Always"; # Always show scrollbars
        AppleScrollerPagingBehavior = true; # Jump to clicked position in scrollbar
        NSTableViewDefaultSizeMode = 2; # Medium sidebar icons
        NSUseAnimatedFocusRing = false; # Disable focus ring animation
        NSScrollAnimationEnabled = true; # Smooth scrolling

        # Dark mode and appearance
        AppleInterfaceStyle = "Dark"; # Force dark mode
        AppleInterfaceStyleSwitchesAutomatically = false; # Disable auto switching

        # Better text input (beyond what you already have)
        ApplePressAndHoldEnabled = false; # Enable key repeat vs special chars
        NSTextShowsControlCharacters = true; # Show control characters
        NSAutomaticSpellingCorrectionEnabled = false; # Already disabled in your config
        NSAutomaticInlinePredictionEnabled = false; # Disable predictive text

        # Finder-related global settings
        AppleShowAllExtensions = true; # Show all file extensions
        AppleShowAllFiles = false; # Don't show hidden files globally (Finder has its own)

        # Regional settings (using metric system)
        AppleICUForce24HourTime = true; # 24-hour clock
        AppleMeasurementUnits = "Centimeters"; # Metric system
        AppleMetricUnits = 1; # Enable metric
        AppleTemperatureUnit = "Celsius"; # Celsius for temperature

        # Misc productivity
        AppleEnableMouseSwipeNavigateWithScrolls = true; # Swipe to navigate
        AppleEnableSwipeNavigateWithScrolls = true; # Swipe to navigate
        AppleSpacesSwitchOnActivate = false; # Don't switch to app's space on activate
        _HIHideMenuBar = false; # Don't auto-hide menu bar
      };

      CustomUserPreferences = {
        # Activity Monitor preferences
        "com.apple.ActivityMonitor" = {
          ShowCategory = 100; # Show all processes
          SortColumn = "CPUUsage";
          SortDirection = 0;
          OpenMainWindow = true;
          IconType = 5; # CPU Usage
          UpdatePeriod = 2; # Update every 2 seconds
        };

        # Additional security settings for screensaver
        "com.apple.screensaver" = lib.mkForce {
          askForPassword = 1; # Require password after sleep/screensaver
          askForPasswordDelay = 5; # 5 second grace period
        };

        # Additional preferences
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };

        # Terminal preferences
        "com.apple.Terminal" = {
          SecureKeyboardEntry = true; # Enable secure keyboard entry in Terminal
          ShowLineMarks = false;
        };

        # TextEdit preferences
        "com.apple.TextEdit" = {
          RichText = false; # Use plain text by default
          PlainTextEncoding = 4; # UTF-8
          PlainTextEncodingForWrite = 4;
        };

        # Menu bar clock settings
        "com.apple.menuextra.clock" = {
          DateFormat = "EEE d MMM HH:mm:ss"; # Show day, date, and time with seconds
          FlashDateSeparators = false;
          IsAnalog = false;
        };
      };
    };
  };
}
