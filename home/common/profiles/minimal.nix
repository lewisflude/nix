{ ... }:
{
  imports = [
    # Core features (shell, git, ssh, gpg, sops, nix, terminal, nh)
    # Note: This now includes terminal.nix and nh.nix which weren't in the original minimal profile
    # If needed, we can add toggle options to features/core to selectively disable features
    ../features/core

    # Essential applications
    ../apps/bat.nix
    ../apps/direnv.nix
    ../apps/fzf.nix
    ../apps/ripgrep.nix
    ../apps/eza.nix
    ../apps/jq.nix

    # Library helpers
    ../lib

    # Custom modules
    ../modules.nix
  ];
}
