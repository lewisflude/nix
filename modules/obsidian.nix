# Obsidian configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.obsidian
_:
{
  flake.modules.homeManager.obsidian =
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
    };
}
