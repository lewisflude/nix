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
  flake.modules.darwin.apps =
    { lib, ... }:
    {
      # ========================================================================
      # Activation Scripts
      # ========================================================================
      # nix-darwin only runs preActivation / extraActivation / postActivation
      # (plus its built-ins); custom-named activation scripts are ignored.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        for dir in /usr/local/share/zsh /usr/local/share/man /usr/local/share/info; do
          if [ -d "$dir" ]; then
            /usr/sbin/chown -R root:wheel "$dir"
          fi
        done

        # Power management (pro audio / KVM reliability).
        #
        # nix-darwin's `power.sleep.*` writes with `pmset -a`, which applies the
        # same profile to every power source. That kept the display and disks
        # awake on battery too, which drains the machine badly when unplugged.
        # Set the two profiles separately instead: never sleep on AC, where the
        # DAW and KVM need it, and normal laptop behaviour on battery.

        # AC: pro audio / KVM — never sleep.
        /usr/bin/pmset -c displaysleep 0 sleep 0 disksleep 0

        # Battery: conserve. Power Nap off so sleep actually stays asleep.
        /usr/bin/pmset -b displaysleep 5 sleep 15 disksleep 10 powernap 0
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
        pkgs.circleci-cli
        pkgs.ninja
        pkgs.portaudio
        pkgs.switchaudio-osx
        pkgs.xcodebuild
      ];
    };
}
