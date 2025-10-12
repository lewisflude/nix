{
  hostname,
  username,
  lib,
  ...
}: {
  environment.etc."sudoers.d/timeout".text = ''
    Defaults timestamp_timeout=30
  '';
  power = {
    sleep = {
      display = 30;
      computer = 60;
    };
  };
  networking = {
    hostName = hostname;
    computerName = hostname;
    localHostName = hostname;
  };
  services.openssh = {
    enable = true;
  };
  system = {
    primaryUser = username;
    defaults = lib.mkMerge [
      {
        dock.persistent-apps = let
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
            "/Applications/Steam.app"
          ];
          systemApps = [
            "/System/Applications/System Settings.app"
          ];
        in
          homebrewApps ++ systemApps;
      }
      {
        dock = {
          persistent-others = [
            "/Users/${username}/Downloads"
            "/Users/${username}/Documents"
          ];
        };
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
            FXPreferredViewStyle = "Nlsv";
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
        NSGlobalDomain = {
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          KeyRepeat = 5;
          InitialKeyRepeat = 15;
          "com.apple.trackpad.scaling" = 0.5;
          "com.apple.trackpad.trackpadCornerClickBehavior" = 1;
          "com.apple.swipescrolldirection" = false;
          "com.apple.mouse.tapBehavior" = 1;
          "com.apple.sound.beep.feedback" = 0;
          "com.apple.sound.beep.volume" = 0.0;
          "com.apple.keyboard.fnState" = true;
        };
        trackpad = {
          Clicking = true;
          TrackpadRightClick = true;
        };
      }
    ];
  };
}
