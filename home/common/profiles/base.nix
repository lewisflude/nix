{ ... }:
{
  imports = [
    # Core features (shell, git, ssh, gpg, sops, nix, terminal, nh)
    ../features

    # Common applications
    ../apps/bat.nix
    ../apps/direnv.nix
    ../apps/fzf.nix
    ../apps/ripgrep.nix
    ../apps/eza.nix
    ../apps/jq.nix
    ../apps/helix.nix
    ../apps/zed-editor.nix
    ../apps/lazygit.nix
    ../apps/atuin.nix
    ../apps/zellij.nix
    ../apps/core-tooling.nix
    ../apps/gemini-cli.nix
    ../apps/claude-code.nix

    ../apps/packages.nix

    # Library helpers
    ../lib

    # Custom modules
    ../modules.nix

    # Theming system
    ../theming
  ];
}
