{ config, pkgs, ... }: {
  # Add user packages
  environment.systemPackages = with pkgs; [ ext4fuse ];

  # Configure Homebrew
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [ "homebrew/cask" "homebrew/core" "homebrew/bundle" ];

    brews = [ ];

    casks = [ "1password" "chatgpt" "ghostty" ];

    masApps = {
      "1Password for Safari" = 1569813296;
      "Kagi Search" = 1622835804;
      "Slack" = 803453959;
      "Xcode" = 497799835;
      "Yubico Authenticator" = 1497506650;
    };
  };
}
