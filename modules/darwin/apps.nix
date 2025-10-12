_: {
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
    casks = [
      "1password@beta"
      "ableton-live-suite"
      "adobe-creative-cloud"
      "beekeeper-studio"
      "betterdisplay"
      "chatgpt"
      "discord"
      "docker-desktop"
      "epic-games"
      "figma"
      "google-chrome@canary"
      "gpg-suite"
      "imageoptim"
      "linear-linear"
      "logi-options+"
      "logitune"
      "musescore"
      "notion"
      "obs@beta"
      "philips-hue-sync"
      "raycast"
      "responsively"
      "slack"
      "steam"
      "moonlight"
      "whatsapp"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "Kagi Search" = 1622835804;
      "Xcode" = 497799835;
      "Yubico Authenticator" = 1497506650;
      "Keka" = 470158793;
    };
  };
}
