# Mercury - Darwin (macOS) workstation
# Follows dendritic pattern: ALL modules imported here, not in infrastructure
{ config, inputs, ... }:
let
  constants = config.constants;
  inherit (config) username useremail;
  inherit (config.flake.modules) darwin homeManager;
in
{
  configurations.darwin.mercury.module =
    { pkgs, ... }:
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
        darwin.karabiner
      ];

      # Required for Darwin
      nixpkgs.hostPlatform = "aarch64-darwin";

      # =========================================================================
      # Home-Manager Module Imports (Dendritic: at host level)
      # =========================================================================
      home-manager.users.${username} =
        { lib, ... }:
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
            homeManager.geminiCli
            homeManager.yazi
            homeManager.mpv
            homeManager.obsidian
            homeManager.zed
            homeManager.developmentTools

            # Darwin-specific home-manager modules
            homeManager.darwinHome
            homeManager.karabiner
            homeManager.audioDarwin

            # Theming (cross-platform signal-nix)
            homeManager.theming
          ];
        };

      # =========================================================================
      # Host Identity
      # =========================================================================
      host = {
        username = username;
        useremail = useremail;
        hostname = "mercury";
        system = "aarch64-darwin";

        features = {
          desktop.enable = true;

          productivity.enable = true;

          security = {
            enable = true;
            yubikey = true;
            gpg = true;
          };

          development = {
            enable = true;
            nix = true;
            git = true;
          };
        };
      };

      # =========================================================================
      # Core System Configuration
      # =========================================================================
      networking.hostName = "mercury";
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
        };
        finder = {
          AppleShowAllExtensions = true;
          FXEnableExtensionChangeWarning = false;
        };
        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          "com.apple.swipescrolldirection" = false;
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
