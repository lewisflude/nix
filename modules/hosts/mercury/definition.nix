# Mercury - Darwin (macOS) workstation
# Follows dendritic pattern: ALL modules imported here, not in infrastructure
{ config, inputs, ... }:
let
  inherit (config) constants;
  inherit (config) username;
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
        darwin.nix
        darwin.nixpkgs
        darwin.sops
        darwin.users
        darwin.homeManagerBase

        # ═══════════════════════════════════════════════════════════════════════
        # Darwin Feature Modules
        # ═══════════════════════════════════════════════════════════════════════
        darwin.shell
        darwin.audio
        darwin.apps
        darwin.disableBackgroundAgents
        darwin.gaming
        darwin.mosh
        darwin.ssh
        darwin.tailscale
        darwin.zed
        darwin.jupiter-music
        darwin.musicProduction
        darwin.vrchatCreation
        darwin.organize
        darwin.githubRunners
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

            # Core home-manager modules
            homeManager.shell
            homeManager.git
            homeManager.ssh
            homeManager.gpg
            homeManager.terminal
            homeManager.xdg
            homeManager.nh
            homeManager.jupiter-music
            homeManager.sops
            homeManager.nixUser

            # CLI apps and editors
            homeManager.cliApps
            homeManager.zellij
            homeManager.gh
            homeManager.git-cliff
            homeManager.helix
            homeManager.claudeCode
            homeManager.codex
            homeManager.antigravityCli
            homeManager.iaGet
            homeManager.yazi
            homeManager.nicotinePlus
            homeManager.obsidian
            homeManager.syncthing
            homeManager.zed
            homeManager.developmentTools
            homeManager.javascript
            homeManager.electronics
            homeManager.organize

            # VRChat creation tools
            homeManager.vrchatCreation

            # Darwin-specific home-manager modules
            homeManager.darwin
            homeManager.karabiner
            homeManager.audio

            # Theming: signal-nix colours apps (cross-platform); theming provides
            # fontconfig here (its GTK/icon bits are Linux-gated). macOS system
            # chrome can't be themed, so signal is home-manager only on Darwin.
            homeManager.theming
            homeManager.signal
          ];
        };

      # =========================================================================
      # Core System Configuration
      # =========================================================================
      networking.hostName = "mercury";
      system.stateVersion = constants.defaults.darwinStateVersion;
      system.primaryUser = username;
    };
}
