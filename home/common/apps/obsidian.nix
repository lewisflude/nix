{ pkgs, ... }:
{
  # The programs.obsidian module doesn't create this directory,
  # leading to activation failures.
  home.file.".config/obsidian/.keep".text = "";

  programs.obsidian = {
    package = pkgs.obsidian;
    vaults = {
      "Obsidian Vault" = {
        enable = true;
      };
    };
  };
}
