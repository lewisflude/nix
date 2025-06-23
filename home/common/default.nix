{
  lib,
  system,
  ...
}:
{
  imports =
    [
      # Cross-platform modules
      ./apps.nix
      ./git.nix
      ./shell.nix
      ./ssh.nix
      ./terminal.nix
      ./theme.nix
      ./development
      ./system
      ./lib

      # Linux-specific modules (desktop environment)
    ]
    ++ lib.optionals (lib.hasInfix "linux" system) [
      ./desktop
    ];

  # Enable direnv for development environments
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
