{ inputs, ... }: {
  imports = [
    ./apps.nix
    ./git.nix
    ./shell.nix
    ./ssh.nix
    ./theme.nix
    ./gpg.nix
    ./development
    ./system
    ./lib
    ./modules.nix
    ./terminal.nix
    ./nh.nix
    ./apps/atuin.nix
    ./apps/lazygit.nix
    ./apps/lazydocker.nix
    ./apps/zellij.nix
    ./apps/micro.nix
    ./apps/eza.nix
    ./apps/jq.nix
  ];
}
