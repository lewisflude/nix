# Darwin Feature Module
# Homebrew casks, brews, Mac App Store apps, and Darwin-specific home-manager packages
{ inputs, ... }:
{
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
        # universalaccess.* is TCC-protected — set manually in
        # System Settings → Accessibility → Display.
        # Pro audio optimizations
        CustomUserPreferences = {
          NSGlobalDomain = {
            "com.apple.sound.beep.volume" = 0.0;
            "com.apple.sound.uiaudioenabled" = 0;
          };
          # Scope App Nap opt-out to the DAW only. Applying NSAppSleepDisabled
          # to NSGlobalDomain keeps every background app resident and starves
          # the DAW of memory under load.
          "com.ableton.live".NSAppSleepDisabled = true;
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

      # Work around Homebrew API regressions during activation by forcing
      # cask/formula resolution through the local taps instead of JSON API
      # responses fetched at switch time.
      environment.variables = {
        HOMEBREW_NO_ENV_HINTS = "1";
        HOMEBREW_NO_INSTALL_FROM_API = "1";
      };

      # ========================================================================
      # nix-homebrew
      # ========================================================================
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = config.host.username;
        autoMigrate = true;
        # Declarative taps: with HOMEBREW_NO_INSTALL_FROM_API=1, brew resolves
        # casks/formulae from local tap clones. Pinning them as flake inputs
        # removes the runtime clone step from activation.
        taps = {
          "homebrew/homebrew-core" = inputs.homebrew-core;
          "homebrew/homebrew-cask" = inputs.homebrew-cask;
          "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
        };
        mutableTaps = false;
      };

      # ========================================================================
      # Homebrew Configuration
      # ========================================================================
      homebrew = {
        enable = true;
        onActivation = {
          cleanup = "zap";
          # Keep `darwin-rebuild switch` deterministic. Homebrew's current API
          # path is failing on several casks during activation; update Brew
          # explicitly outside activation until that is resolved upstream.
          autoUpdate = false;
          upgrade = true;
        };
        caskArgs = {
          no_quarantine = true;
        };
        taps = builtins.attrNames config.nix-homebrew.taps;
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
          "linear"
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
