# Obsidian configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.obsidian
{ config, ... }:
{
  flake.modules.homeManager.obsidian = { lib, pkgs, config, ... }: {
    home.file.".config/obsidian/.keep".text = "";

    programs.obsidian = {
      package = pkgs.obsidian;
      vaults = {
        "Obsidian Vault" = { enable = true; };
      };
    };
  };
}
