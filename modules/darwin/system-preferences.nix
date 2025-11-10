{
  lib,
  config,
  ...
}:
let
  cfg = config.host.features.systemPreferences;
in
{
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

        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowResizeTime = 0.001;
        NSWindowShouldDragOnGesture = true;

        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;

        NSDocumentSaveNewDocumentsToCloud = false;
        AppleWindowTabbingMode = "always";

        AppleShowScrollBars = "Always";
        AppleScrollerPagingBehavior = true;
        NSTableViewDefaultSizeMode = 2;
        NSUseAnimatedFocusRing = false;
        NSScrollAnimationEnabled = true;

        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = false;

        ApplePressAndHoldEnabled = false;
        NSTextShowsControlCharacters = true;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;

        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;

        AppleICUForce24HourTime = true;
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleTemperatureUnit = "Celsius";

        AppleEnableMouseSwipeNavigateWithScrolls = true;
        AppleEnableSwipeNavigateWithScrolls = true;
        AppleSpacesSwitchOnActivate = false;
        _HIHideMenuBar = false;
      };
    };
  };
}
