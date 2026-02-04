# nix-your-shell - Wrapper to retain your shell in nix develop/nix-shell
# Dendritic pattern: Full implementation as flake.modules.homeManager.nixYourShell
{ config, ... }:
{
  flake.modules.homeManager.nixYourShell =
    { lib, pkgs, ... }:
    {
      programs.nix-your-shell = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
