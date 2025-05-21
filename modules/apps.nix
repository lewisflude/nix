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
      "chatgpt"
      "gpg-suite"
      "docker"
      "figma"
      "adobe-creative-cloud"
      "notion"
      "slack"
      "raycast"
      "insomnia"
      "tableplus"
      "logitech-options"
      "logitech-g-hub"
      "ghostty"
      "firefox@developer-edition"
      "google-chrome"
      "responsively"
      "imageoptim"
      "figma"
      "linear-linear"
      "logi-options+"
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
