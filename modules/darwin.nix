# Darwin Feature Module
# Homebrew casks, brews, Mac App Store apps, and Darwin-specific home-manager packages
_: {
  # ==========================================================================
  # Darwin System Configuration
  # ==========================================================================
  flake.modules.darwin.apps =
    { config, ... }:
    {
      # ========================================================================
      # Activation Scripts
      # ========================================================================
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

      # ========================================================================
      # macOS System Preferences
      # ========================================================================
      system.defaults = {
        dock = {
          autohide = true;
          show-recents = false;
          mineffect = "scale";
        };
        finder = {
          AppleShowAllExtensions = true;
          FXEnableExtensionChangeWarning = false;
        };
        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          "com.apple.swipescrolldirection" = false;
          NSAutomaticWindowAnimationsEnabled = false;
        };
        universalaccess = {
          reduceMotion = true;
          reduceTransparency = true;
        };
        # Pro audio optimizations
        CustomUserPreferences = {
          NSGlobalDomain = {
            NSAppSleepDisabled = true;
            "com.apple.sound.beep.volume" = 0.0;
            "com.apple.sound.uiaudioenabled" = 0;
          };
          "com.apple.SoftwareUpdate" = {
            AutomaticCheckEnabled = false;
            AutomaticDownload = false;
          };
        };
      };

      # Power management (pro audio / KVM reliability)
      power.sleep.computer = "never";
      power.sleep.display = "never";
      power.sleep.harddisk = "never";

      # Touch ID for sudo
      security.pam.services.sudo_local.touchIdAuth = true;

      # ========================================================================
      # nix-homebrew
      # ========================================================================
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = config.host.username;
        autoMigrate = true;
      };

      # ========================================================================
      # Homebrew Configuration
      # ========================================================================
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
          "switchaudio-osx"
        ];
        casks = [
          "1password@beta"
          "ableton-live-suite"
          "betterdisplay"
          "blender"
          "claude"
          "discord"
          "figma"
          "ghostty"
          "google-chrome"
          "gpg-suite"
          "imageoptim"
          "linear-linear"
          "logi-options+"
          "logitune"
          "loom"
          "philips-hue-sync"
          "raycast"
          "slack"
          "whatsapp"
        ];
        # Mac App Store apps are installed manually.
        # `mas install` fails non-deterministically against Apple's App Store
        # service (even for already-installed apps), which blocks activation.
        # Install via the App Store UI instead.
        masApps = { };
      };
    };

  # ==========================================================================
  # Darwin Home-Manager Configuration
  # ==========================================================================
  flake.modules.homeManager.darwin =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isDarwin {
      home.packages = [
        pkgs.ninja
        pkgs.portaudio
        pkgs.xcodebuild
      ];
    };
}
