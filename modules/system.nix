{ pkgs, hostname, ... }: {

  # Fonts
  fonts = { packages = with pkgs; [ nerd-fonts.jetbrains-mono ]; };

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
    };

    # Trackpad Settings
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      # TrackpadScroll is not a valid option
      # TrackpadSpeed is not a valid option
    };

    # Firewall Settings
    alf = {
      globalstate = 1;
      allowsignedenabled = 1;
    };
  };
}
