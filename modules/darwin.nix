# Darwin Feature Module
# Homebrew casks, brews, Mac App Store apps, and Darwin-specific home-manager packages
{ config, ... }:
let
  # Captured from the top-level scope before the darwin module shadows `config`.
  inherit (config) username;
in
{
  # ==========================================================================
  # Darwin System Configuration
  # ==========================================================================
  flake.modules.darwin.apps = _: {
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

    # Power management (pro audio / KVM reliability).
    #
    # nix-darwin's `power.sleep.*` writes with `pmset -a`, which applies the
    # same profile to every power source. That kept the display and disks
    # awake on battery too, which drains the machine badly when unplugged.
    # Set the two profiles separately instead: never sleep on AC, where the
    # DAW and KVM need it, and normal laptop behaviour on battery.
    system.activationScripts.powerProfiles = ''
      # AC: pro audio / KVM — never sleep.
      pmset -c displaysleep 0 sleep 0 disksleep 0

      # Battery: conserve. Power Nap off so sleep actually stays asleep.
      pmset -b displaysleep 5 sleep 15 disksleep 10 powernap 0
    '';

    # Touch ID for sudo
    security.pam.services.sudo_local.touchIdAuth = true;

    environment.variables.HOMEBREW_NO_ENV_HINTS = "1";

    # ========================================================================
    # nix-homebrew
    # ========================================================================
    nix-homebrew = {
      enable = true;
      enableRosetta = true;
      user = username;
      autoMigrate = true;
    };

    # ========================================================================
    # Homebrew Configuration
    # ========================================================================
    homebrew = {
      enable = true;
      onActivation = {
        cleanup = "zap";
        # Keep activation idempotent: run `brew update` explicitly to pick up
        # new package versions.
        autoUpdate = false;
        upgrade = true;
      };
      caskArgs = {
        no_quarantine = true;
      };
      brews = [
        "circleci"
        "mas"
        "switchaudio-osx"
      ];
      casks = [
        "1password@beta"
        "ableton-live-suite"
        "betterdisplay"
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
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      home.packages = [
        pkgs.ninja
        pkgs.portaudio
        pkgs.xcodebuild
      ];
    };
}
