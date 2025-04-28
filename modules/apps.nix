{ config, pkgs, username, homebrew-cask, homebrew-core, homebrew-bundle, ...
}: {

  # Configure Homebrew
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
      upgrade = true;
    };

    brews = [ ];

    # GUI applications
    casks = [
      "1password"
      "chatgpt"
      "docker" # Docker Desktop
      "figma"
      "notion"
      "slack"
      "rectangle"
      "raycast"
      "postman"
      "tableplus"
      "warp"
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
