{ ... }:
{
  imports = [
    ../shell.nix
    ../git.nix
    ../ssh.nix
    ../gpg.nix
    ../nix-config.nix

    ../apps/bat.nix
    ../apps/direnv.nix
    ../apps/fzf.nix
    ../apps/ripgrep.nix
    ../apps/eza.nix
    ../apps/jq.nix

    ../lib

    ../modules.nix
  ];
}
