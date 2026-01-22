{ inputs, ... }:
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

  # Use pre-built weekly database (much faster than building yourself)
  # This provides a ~200MB index updated weekly, saving 30+ minutes of build time
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ];
}
