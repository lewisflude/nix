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
      ./lib

    ]
    ++ lib.optionals (lib.hasInfix "linux" system) [
      ./desktop
    ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
