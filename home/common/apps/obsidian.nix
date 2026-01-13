{ pkgs, ... }:
{
  programs.obsidian = {
    package = pkgs.obsidian;
    vaults = {
      "Obsidian Vault" = {
        enable = true;
      };
    };
  };
}
