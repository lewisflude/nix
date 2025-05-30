{ ... }: {
  # Configure Homebrew
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    caskArgs = { no_quarantine = true; };
    taps = [ "nrwl/nx" "j178/tap" ];
    brews = [ "prefligit" ];
    # GUI applications
    casks = [
      "1password"
      "ableton-live-suite"
      "adobe-creative-cloud"
      "chatgpt"
      "docker"
      "figma"
      "figma"
      "ghostty"
      "google-chrome"
      "gpg-suite"
      "imageoptim"
      "insomnia"
      "linear-linear"
      "logi-options+"
      "logitech-g-hub"
      "logitech-options"
      "notion"
      "raycast"
      "responsively"
      "slack"
      "tableplus"
    ];

    # Mac App Store applications
    masApps = {
      "1Password for Safari" = 1569813296;
      "Kagi Search" = 1622835804;
      "Slack" = 803453959;
      "Xcode" = 497799835;
      "Yubico Authenticator" = 1497506650;
    };
  };
}
