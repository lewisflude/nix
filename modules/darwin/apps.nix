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
  # This prevents mas installation failures due to authentication issues
  # Runs early (alphabetically before homebrew) to catch issues before installation
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
      # Check for the specific error we're seeing (PKInstallErrorDomain Code=201)
      # This usually means the installation service can't be accessed
      echo ""
      echo "⚠️  WARNING: Mac App Store authentication issue detected"
      echo ""
      echo "   mas cannot access the App Store installation service."
      echo "   This usually means:"
      echo "   1. You're not signed into the App Store app, OR"
      echo "   2. macOS security is blocking mas from accessing the service"
      echo ""
      echo "   To fix this:"
      echo "   1. Open the App Store app (open -a 'App Store')"
      echo "   2. Sign in with your Apple ID (Store > Sign In)"
      echo "   3. Try installing an app manually to verify authentication works"
      echo "   4. Run 'darwin-rebuild switch' again"
      echo ""
      echo "   If mas installations still fail after signing in:"
      echo "   - Install mas apps manually from the App Store"
      echo "   - mas will recognize them and won't try to reinstall"
      echo ""
      echo "   The rebuild will continue, but mas app installations may fail."
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
