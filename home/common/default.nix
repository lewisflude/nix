{
  lib,
  system,
  ...
}:
{
  imports =
    [
      ./apps.nix
      ./git.nix
      ./shell.nix
      ./ssh.nix
      ./terminal.nix
      ./theme.nix
      ./gpg.nix
      ./development
      ./system
      ./sops.nix
      ./lib
      ./modules.nix
    ]
    ++ lib.optionals (lib.hasInfix "linux" system) [
      ./desktop
    ];

}
