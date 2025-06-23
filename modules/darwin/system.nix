{
  pkgs,
  hostname,
  username,
  config,
  ...
}:
{

  # System Libraries
  environment.systemPackages = with pkgs; [
    libiconv
    pkg-config
    ext4fuse
    openssl
    postgresql_16
  ];

  # Power Management Settings
  power = {
    sleep = {
      display = 30;
      computer = 60;
    };
  };

  # Fonts - temporarily disabled due to Python compatibility issues
  # fonts = {
  #   packages = with pkgs; [
  #     nerd-fonts.jetbrains-mono
  #     nerd-fonts.iosevka
  #   ];
  # };

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
  environment.etc."ssh/ssh_config.d/secure.conf".text = ''
    # Secure SSH configuration
    Host *
      PasswordAuthentication no
      PubkeyAuthentication yes
  '';

  system.primaryUser = username;

  # macOS System Settings
  system.defaults = {
    # Dock Settings
    dock = {
      # Frontend Developer Setup - TypeScript/React focused
      persistent-apps = [
        # Primary development tools (most used)
        "/System/Volumes/Data/Applications/Docker.app"
        "/Users/${username}/Applications/Home Manager Trampolines/Firefox Developer Edition.app" # Primary browser for development

        # Design & Planning
        "/System/Volumes/Data/Applications/Figma.app"
        "/System/Volumes/Data/Applications/Notion.app"
        "/System/Volumes/Data/Applications/Obsidian.app"

        # Communication & Database
        "/Users/${username}/Applications/Home Manager Trampolines/Slack.app"
        "/Users/${username}/Applications/Home Manager Trampolines/TablePlus.app"

        # System utilities
        "/System/Applications/System Settings.app"
      ];

      # Persistent folders (optional)
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

    # Firewall Settings
    alf = {
      globalstate = 1;
      allowsignedenabled = 1;
    };
  };
  nix.extraOptions = ''
    extra-sandbox-paths = /System/Library/Frameworks /Library/Frameworks
  '';
}
