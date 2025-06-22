{
  catppuccin,
  username,
  ...
}:
{
  imports = [
    ./git.nix
    ./shell.nix
    ./apps.nix
    ./ssh.nix
    ./theme.nix
    ./direnv.nix
    ./python.nix
    catppuccin.homeModules.catppuccin
  ];
}