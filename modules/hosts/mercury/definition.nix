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
            homeManager.zellij
            homeManager.gh
            homeManager.git-cliff
            homeManager.helix
            homeManager.powerlevel10k
            homeManager.claudeCode
            homeManager.geminiCli
            homeManager.iaGet
            homeManager.mpv
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
        hostname = "mercury";

        features = { };
      };

      # =========================================================================
      # Core System Configuration
      # =========================================================================
      networking.hostName = "mercury";
      system.stateVersion = constants.defaults.darwinStateVersion;
      system.primaryUser = "lewisflude";
    };
}
