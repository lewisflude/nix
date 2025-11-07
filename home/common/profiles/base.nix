{ ... }:
{
  imports = [

    ../shell.nix
    ../git.nix
    ../ssh.nix
    ../gpg.nix
    ../nix-config.nix
    ../terminal.nix
    ../nh.nix

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

    ../apps/packages.nix

    ../lib

    ../modules.nix

    # Theming system
    ../theming

    # Feature modules (includes security with sops)
    ../features
  ];
}
