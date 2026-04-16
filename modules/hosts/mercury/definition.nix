# Mercury - Darwin (macOS) workstation
# Follows dendritic pattern: ALL modules imported here, not in infrastructure
{ config, inputs, ... }:
let
  inherit (config) constants;
  inherit (config) username useremail;
  inherit (config.flake.modules) darwin homeManager;
in
{
  configurations.darwin.mercury.module =
    { ... }:
    {
      imports = [
        # ═══════════════════════════════════════════════════════════════════════
        # External Input Modules (Darwin)
        # ═══════════════════════════════════════════════════════════════════════
        inputs.home-manager.darwinModules.home-manager
        inputs.sops-nix.darwinModules.sops
        inputs.determinate.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew

        # ═══════════════════════════════════════════════════════════════════════
        # Core Modules (dendritic: each concern has its own module)
        # ═══════════════════════════════════════════════════════════════════════
        darwin.hostOptions
        darwin.nix
        darwin.nixpkgs
        darwin.sops
        darwin.users
        darwin.determinate
        darwin.homeManagerBase

        # ═══════════════════════════════════════════════════════════════════════
        # Darwin Feature Modules
        # ═══════════════════════════════════════════════════════════════════════
        darwin.shell
        darwin.audio
        darwin.apps
        darwin.gaming
        darwin.karabiner
        darwin.ssh
        darwin.zed
        darwin.nfs
        darwin.vrchatCreation
      ];

      # Required for Darwin
      nixpkgs.hostPlatform = "aarch64-darwin";

      # =========================================================================
      # Home-Manager Module Imports (Dendritic: at host level)
      # =========================================================================
      home-manager.users.${username} =
        { ... }:
        {
          imports = [
            # External home-manager modules
            inputs.nix-index-database.homeModules.nix-index
            inputs.sops-nix.homeManagerModules.sops
            inputs.signal-nix.homeManagerModules.default

            # Core home-manager modules
            homeManager.shell
            homeManager.git
            homeManager.ssh
            homeManager.gpg
            homeManager.terminal
            homeManager.xdg
            homeManager.nh
            homeManager.nfs
            homeManager.sops
            homeManager.nixUser

            # CLI apps and editors
            homeManager.cliApps
            homeManager.atuin
            homeManager.direnv
            homeManager.fzf
            homeManager.zellij
            homeManager.gh
            homeManager.git-cliff
            homeManager.helix
            homeManager.nixYourShell
            homeManager.powerlevel10k
            homeManager.userPackages
            homeManager.claudeCode
            homeManager.yazi
            homeManager.nicotinePlus
            homeManager.obsidian
            homeManager.zed
            homeManager.developmentTools

            # VRChat creation tools
            homeManager.vrchatCreation

            # Darwin-specific home-manager modules
            homeManager.darwin
            homeManager.karabiner
            homeManager.audio

            # Theming (cross-platform signal-nix)
            homeManager.theming
          ];
        };

      # =========================================================================
      # Host Identity
      # =========================================================================
      host = {
        inherit username;
        inherit useremail;
        hostname = "mercury";
        system = "aarch64-darwin";

        features = { };
      };

      # =========================================================================
      # Core System Configuration
      # =========================================================================
      networking.hostName = "mercury";

      # =========================================================================
      # Power Management (pro audio / KVM reliability)
      # =========================================================================
      power.sleep.computer = "never";
      power.sleep.display = "never";
      power.sleep.harddisk = "never";

      system.activationScripts.disableSpotlightNixStore.text = ''
        if [ -d "/nix/store" ]; then
          mdutil -i off /nix/store 2>/dev/null || true
        fi
      '';

      system.stateVersion = constants.defaults.darwinStateVersion;

      # Primary user for user-specific options (required by nix-darwin)
      # On macOS, the actual system user is "lewisflude"
      system.primaryUser = "lewisflude";

      # =========================================================================
      # macOS System Preferences
      # =========================================================================
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
            # Disable App Nap (prevents macOS throttling background audio apps)
            NSAppSleepDisabled = true;
            # Silence alert sounds (prevents unexpected audio through interface)
            "com.apple.sound.beep.volume" = 0.0;
            # Disable UI sounds (empty trash, screenshots, etc.)
            "com.apple.sound.uiaudioenabled" = 0;
          };
          "com.apple.SoftwareUpdate" = {
            # Disable background update checks during audio sessions
            AutomaticCheckEnabled = false;
            AutomaticDownload = false;
          };
        };
      };

      # Enable Touch ID for sudo
      security.pam.services.sudo_local.touchIdAuth = true;

      # =========================================================================
      # Homebrew (via nix-homebrew)
      # =========================================================================
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = "lewisflude";
        autoMigrate = true;
      };
    };
}
