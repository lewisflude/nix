# Base profile
# Essential user tools that should be available on all systems
# These are always included regardless of feature flags
{...}: {
  imports = [
    # Core configuration
    ../shell.nix
    ../git.nix
    ../ssh.nix
    ../gpg.nix
    ../nix-config.nix
    ../terminal.nix
    ../nh.nix

    # Essential apps that are lightweight and universally useful
    ../apps/bat.nix
    ../apps/direnv.nix
    ../apps/fzf.nix
    ../apps/ripgrep.nix
    ../apps/eza.nix
    ../apps/jq.nix
    ../apps/helix.nix
    ../apps/lazygit.nix
    ../apps/atuin.nix
    ../apps/micro.nix
    ../apps/zellij.nix

    # Additional packages
    ../apps/packages.nix

    # SOPS secrets
    ../sops.nix

    # Library functions
    ../lib

    # Custom modules
    ../modules.nix
  ];
}
