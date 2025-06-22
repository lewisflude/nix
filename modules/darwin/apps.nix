{ ... }:
{
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
    taps = [
      "nrwl/nx"
      "j178/tap"
    ];
    brews = [
      "circleci"
      "prefligit"
      "nx"
    ];
    # GUI applications
    casks = [
      "1password@beta"
      "ableton-live-suite"
      "adobe-creative-cloud"
      "betterdisplay"
      "chatgpt"
      "docker"
      "figma"
      "ghostty"
      "gpg-suite"
      "imageoptim"
      "linear-linear"
      "notion"
      "obs@beta"
      "obsidian"
      "raycast"
      "responsively"
    ];

    # Mac App Store applications
    masApps = {
      "1Password for Safari" = 1569813296;
      "Kagi Search" = 1622835804;
      "Xcode" = 497799835;
      "Yubico Authenticator" = 1497506650;
    };
  };
}
