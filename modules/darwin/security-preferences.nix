{
  lib,
  config,
  ...
}: let
  cfg = config.host.features.securityPreferences;
in {
  options.host.features.securityPreferences = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable security and firewall preferences";
    };
  };

  config = lib.mkIf cfg.enable {
    # Firewall configuration using networking.applicationFirewall
    networking.applicationFirewall = {
      enable = true; # Enable the firewall
      blockAllIncoming = false; # Allow specific apps (equivalent to globalstate = 1)
      allowSigned = true; # Allow signed applications
      allowSignedApp = true; # Allow signed downloaded applications
      enableStealthMode = false; # Don't enable stealth mode (blocks ping)
    };

    system.defaults = {
      # Note: Software update settings are not available in nix-darwin
      # These would need to be set manually via System Preferences

      # Login window settings
      loginwindow = {
        GuestEnabled = false; # Disable guest account
        DisableConsoleAccess = true; # Disable console access
        SHOWFULLNAME = false; # Show username and password fields
        autoLoginUser = null; # Disable auto-login
        PowerOffDisabledWhileLoggedIn = false; # Allow power off when logged in
        RestartDisabledWhileLoggedIn = false; # Allow restart when logged in
        ShutDownDisabledWhileLoggedIn = false; # Allow shutdown when logged in
        SleepDisabled = false; # Allow sleep
      };
    };

    # Additional security settings via CustomUserPreferences
    system.defaults.CustomUserPreferences = {
      # Gatekeeper and security settings
      "com.apple.security" = {
        allowApplePersonalizedAdvertising = false; # Disable personalized ads
      };

      # Safari security settings
      "com.apple.Safari" = {
        # Privacy and security
        SendDoNotTrackHTTPHeader = true; # Send "Do Not Track" header
        WebKitJavaScriptCanOpenWindowsAutomatically = false; # Block pop-ups
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically" = false;
        UniversalSearchEnabled = false; # Don't send search queries to Apple
        SuppressSearchSuggestions = true; # Don't show search suggestions
        WarnAboutFraudulentWebsites = true; # Warn about fraudulent sites
        WebAutomaticSpellingCorrectionEnabled = false; # Don't auto-correct in web forms

        # Development
        IncludeInternalDebugMenu = true; # Show debug menu
        IncludeDevelopMenu = true; # Show develop menu
        WebKitDeveloperExtrasEnabledPreferenceKey = true; # Enable developer extras
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
      };
    };
  };
}
