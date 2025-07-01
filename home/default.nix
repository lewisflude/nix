{
  username,
  system,
  lib,
  ...
}:
{
  home.stateVersion = "24.05";
  home.username = username;

  # Platform-specific home directory
  home.homeDirectory =
    if lib.hasInfix "darwin" system then "/Users/${username}" else "/home/${username}";

  imports =
    [
      # Common configurations (cross-platform)
      ./common

      # Platform-specific configurations
    ]
    ++ lib.optionals (lib.hasInfix "darwin" system) [
      ./darwin
    ]
    ++ lib.optionals (lib.hasInfix "linux" system) [
      ./nixos
    ];

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

}
