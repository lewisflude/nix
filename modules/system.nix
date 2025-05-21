{ pkgs, hostname, ... }: {

  # System Libraries
  environment.systemPackages = with pkgs; [
    libiconv
    pkg-config
    ext4fuse
    openssl
    docker
    docker-compose
    docker-credential-helpers
    postgresql_16
  ];

  # Power Management Settings
  power = {
    sleep = {
      display = 30;
      computer = 60;
    };
  };

  # Fonts
  fonts = {
    packages = with pkgs; [ nerd-fonts.jetbrains-mono nerd-fonts.iosevka ];
  };

  # Networking
  networking = {
    hostName = hostname;
    computerName = hostname;
    localHostName = hostname;
  };

  # SSH Configuration
  services.openssh = { enable = true; };
  environment.etc."ssh/ssh_config.d/secure.conf".text = ''
    # Secure SSH configuration
    Host *
      PasswordAuthentication no
      PubkeyAuthentication yes
  '';

  system.primaryUser = "lewisflude";

  # macOS System Settings
  system.defaults = {
    # Dock Settings
    dock = {
      # Appearance
      autohide = true;
      magnification = true;
      tilesize = 48;
      mineffect = "genie";
      launchanim = true;

      # Behavior
      static-only = false;
      showhidden = true;
      enable-spring-load-actions-on-all-items = true;
      appswitcher-all-displays = true;
      minimize-to-application = false;
      mouse-over-hilite-stack = true;
      mru-spaces = true;
      slow-motion-allowed = true;

      # Position
      orientation = "left";

      # Mission Control
      expose-animation-duration = 0.5;
      expose-group-apps = true;

      # Hot Corners
      wvous-tl-corner = 2; # Mission Control
      wvous-tr-corner = 4; # Desktop
      wvous-bl-corner = 3; # Application Windows
      wvous-br-corner = 5; # Start Screen Saver
    };

    # Finder Settings
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      CreateDesktop = false;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      _FXShowPosixPathInTitle = true;
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
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" =
          true;
      };
      "com.apple.TimeMachine" = { DoNotOfferNewDisksForBackup = true; };
      "com.apple.menuextra.battery" = { ShowPercent = true; };
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
      "com.apple.keyboard.fnState" =
        true; # Use F1-F12 keys as standard function keys
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
