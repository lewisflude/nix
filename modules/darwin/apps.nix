{
  lib,
  config,
  ...
}: let
  features = config.host.features or {};
  desktopEnabled = (features.desktop or {}).enable or false;
  gamingEnabled = (features.gaming or {}).enable or false;
in {
  system.activationScripts.fixUsrLocalOwnership = ''
    if [ -d "/usr/local/share/zsh" ]; then
      chown -R root:wheel /usr/local/share/zsh
    fi
    if [ -d "/usr/local/share/man" ]; then
      chown -R root:wheel /usr/local/share/man
    fi
    if [ -d "/usr/local/share/info" ]; then
      chown -R root:wheel /usr/local/share/info
    fi
  '';
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
      "j178/tap"
    ];
    brews = [
      "circleci"
      "mas"
    ];
    casks =
      lib.optionals desktopEnabled [
        "1password@beta"
        "ableton-live-suite"
        "adobe-creative-cloud"
        "aws-vpn-client"
        "beekeeper-studio"
        "betterdisplay"
        "chatgpt"
        "discord"
        "docker-desktop"
        "figma"
        "google-chrome@canary"
        "gpg-suite"
        "imageoptim"
        "linear-linear"
        "logi-options+"
        "logitune"
        "musescore"
        "notion"
        "philips-hue-sync"
        "raycast"
        "responsively"
        "slack"
        "whatsapp"
      ]
      ++ lib.optionals gamingEnabled [
        "epic-games"
        "moonlight"
        "obs@beta"
        "steam"
      ];
    masApps = {
      "Kagi Search" = 1622835804;
      "Xcode" = 497799835;
      "Yubico Authenticator" = 1497506650;
      "Keka" = 470158793;
    };
  };
}
