{ ... }:
{
  # Configure Homebrew
  homebrew = {
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
      "mas"
      "node"
      "nx"
    ];
    # GUI applications
    casks = [
      "1password@beta"
      "ableton-live-suite"
      "adobe-creative-cloud"
      "beekeeper-studio"
      "betterdisplay"
      "chatgpt"
      "docker-desktop"
      "figma"
      "ghostty@tip"
      "google-chrome@canary"
      "gpg-suite"
      "imageoptim"
      "linear-linear"
      "logi-options+"
      "notion"
      "obs@beta"
      "raycast"
      "responsively"
      "slack"
    ];

    # Mac App Store applications
    masApps = {
      "1Password for Safari" = 1569813296;
      "Kagi Search" = 1622835804;
      "Xcode" = 497799835;
      "Yubico Authenticator" = 1497506650;
      "Keka" = 470158793;
    };
  };
}
