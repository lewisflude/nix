{  ...
}: {
  # Configure Homebrew
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    caskArgs = {
      no_quarantine = true;
    };

    brews = [ ];

    # GUI applications
    casks = [
      "1password"
      "chatgpt"
      "docker"
      "figma"
      "notion"
      "slack"
      "raycast"
      "insomnia"
      "tableplus"
      "ghostty"
      "logi-options+"
      "logitune"
      "firefox@developer-edition"
      "google-chrome"
      "responsively"
      "imageoptim"
      "figma"
      "linear-linear"
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
