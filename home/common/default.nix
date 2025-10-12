{...}: {
  imports = [
    ./apps.nix
    ./git.nix
    ./shell.nix
    ./ssh.nix
    ./theme.nix
    ./gpg.nix
    ./sops.nix
    ./development
    ./system
    ./lib
    ./modules.nix
    ./terminal.nix
    ./nh.nix
  ];
}
