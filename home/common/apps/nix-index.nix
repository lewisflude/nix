{ ... }:
{
  # Enable nix-index for package search and comma command
  # Usage:
  # - , cowsay "hello"  # Instantly run any command without installing
  # - nix-locate bin/cowsay  # Find which package provides a file
  # - nix-locate --whole-name bin/convert  # Search for exact matches
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  # Note: nix-index-database.homeModules.nix-index is imported at infrastructure level
  # in modules/infrastructure/home-manager.nix for the pre-built weekly database
}
