{
  lib,
  config,
  ...
}:
let
  features = config.host.features or { };
  desktopEnabled = (features.desktop or { }).enable or false;
  gamingEnabled = (features.gaming or { }).enable or false;
in
{
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

  # Pre-check App Store authentication before mas installations
  # If mas isn't authenticated, skip masApps to prevent brew bundle from failing
  system.activationScripts.aaCheckMasAuth = ''
    echo "🔍 Checking Mac App Store authentication for mas..."

    # Check if mas is installed (it might not be on first run)
    if ! command -v mas &> /dev/null; then
      echo "ℹ️  mas is not installed yet, will be installed by Homebrew"
      echo "   After mas is installed, ensure you're signed into the App Store"
      echo "   (Store > Sign In) before mas apps can be installed automatically."
      exit 0
    fi

    # Try to list mas apps - this requires App Store authentication
    # If this fails, mas installations will also fail
    if mas list &> /dev/null 2>&1; then
      echo "✅ Mac App Store authentication verified (mas can list apps)"
    else
      echo ""
      echo "⚠️  WARNING: Mac App Store authentication issue detected"
      echo ""
      echo "   mas cannot access the App Store installation service."
      echo "   This usually means you're not signed into the App Store."
      echo ""
      echo "   To fix:"
      echo "   1. Open the App Store app (open -a 'App Store')"
      echo "   2. Sign in with your Apple ID (Store > Sign In)"
      echo "   3. Run 'darwin-rebuild switch' again"
      echo ""
      echo "   Activation will continue, but mas app installations will fail."
      echo ""
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
        "beekeeper-studio"
        "betterdisplay"
        "chatgpt"
        "discord"
        "docker-desktop"
        "figma"
        "ghostty"
        "google-chrome"
        "gpg-suite"
        "imageoptim"
        "linear-linear"
        "logi-options+"
        "logitune"
        "loom"
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
      "Amphetamine" = 937984704;
      "Kagi Search" = 1622835804;
      # Note: Xcode should be installed manually from App Store or using: mas install 497799835
      # Automated installation via mas often fails due to size and App Store service issues
      "Yubico Authenticator" = 1497506650;
      "Keka" = 470158793;
    };
  };
}
