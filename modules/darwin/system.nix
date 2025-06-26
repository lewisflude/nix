{
  pkgs,
  hostname,
  username,
  lib,
  config,
  ...
}:
{

  # System Libraries
  environment.systemPackages = with pkgs; [
    libiconv
    pkg-config
    openssl
    yubikey-personalization
    yubico-piv-tool
    opensc
    pcsctools
    sops
  ];

  # Sudo and Login Configuration

  environment.etc."sudoers.d/timeout".text = ''
    Defaults timestamp_timeout=30  # Set sudo timeout to 30 minutes
  '';

  # Power Management Settings
  power = {
    sleep = {
      display = 30;
      computer = 60;
    };
  };

  # Networking
  networking = {
    hostName = hostname;
    computerName = hostname;
    localHostName = hostname;
  };

  # SSH Configuration
  services.openssh = {
    enable = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.ssh = {
    extraConfig = ''
      Host *
        PasswordAuthentication no
        PubkeyAuthentication yes
        PKCS11Provider ${pkgs.opensc}/lib/opensc-pkcs11.so
    '';
  };

  system.primaryUser = username;

  system.defaults.dock.persistent-apps =
    let
      homebrewApps = lib.filter (app: builtins.pathExists app) [
        "/Applications/Docker.app"
        "/Applications/Google Chrome Canary.app"
        "/Applications/Figma.app"
        "/Applications/Notion.app"
        "/Applications/Obsidian.app"
        "/Applications/Slack.app"
        "/Applications/Linear.app"
        "/Applications/Raycast.app"
        "/Applications/Beekeeper Studio.app"
        "/Applications/ChatGPT.app"
      ];

      systemApps = [
        "/System/Applications/System Settings.app"
      ];
    in
    homebrewApps ++ systemApps;

  system.defaults = {
    dock = {
      persistent-others = [
        "/Users/${username}/Downloads"
        "/Users/${username}/Documents"
      ];
    };

    # Control Center Settings
    controlcenter = {
      NowPlaying = true;
      Sound = true;
    };

    CustomUserPreferences = {
      "com.apple.screensaver" = {
        askForPassword = 0;
        askForPasswordDelay = 0;
      };
      "com.apple.screencapture" = {
        location = "~/Desktop";
        type = "png";
        disable-shadow = true;
      };
      "com.apple.finder" = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        WebKitDeveloperExtras = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXPreferredViewStyle = "Nlsv"; # List view
        ShowTabView = true;
        ShowSidebar = true;
      };
      "com.apple.Safari" = {
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
      };
      "com.apple.TimeMachine" = {
        DoNotOfferNewDisksForBackup = false;
      };
      "com.apple.menuextra.battery" = {
        ShowPercent = true;
      };
    };

    # Global Domain Settings
    NSGlobalDomain = {
      # Text Input
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;

      # Keyboard
      KeyRepeat = 5;
      InitialKeyRepeat = 15;

      # Trackpad
      "com.apple.trackpad.scaling" = 0.5;
      "com.apple.trackpad.trackpadCornerClickBehavior" = 1;

      # Mouse and Trackpad
      "com.apple.swipescrolldirection" = false; # Natural scrolling
      "com.apple.mouse.tapBehavior" = 1; # Tap to click

      # Sound
      "com.apple.sound.beep.feedback" = 0; # Disable system sound effects
      "com.apple.sound.beep.volume" = 0.0; # Mute system sound

      # Function Keys
      "com.apple.keyboard.fnState" = true; # Use F1-F12 keys as standard function keys
    };

    # Trackpad Settings
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };
}
