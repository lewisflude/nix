# Atuin - Shell history sync and search
{ config, ... }:
{
  flake.modules.homeManager.atuin =
    { ... }:
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        flags = [ "--disable-up-arrow" ];
        settings = {
          sync_frequency = "5m";
        };
      };
    };
}
