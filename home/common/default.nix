{...}: {
  imports = [
    ./apps
    ./git.nix
    ./shell.nix
    ./ssh.nix
    ./theme.nix
    ./gpg.nix
    ./sops.nix
    ./nix-config.nix
    ./development
    ./system
    ./lib
    ./modules.nix
    ./terminal.nix
    ./nh.nix
  ];
}
