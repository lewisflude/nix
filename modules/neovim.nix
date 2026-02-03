# Neovim Editor - Dendritic Pattern
# Minimal neovim configuration for quick edits
{ config, ... }:
{
  flake.modules.homeManager.neovim = { lib, pkgs, osConfig ? {}, ... }:
    let
      cfg = osConfig.host.features.development or {};
      enableNeovim = cfg.enable or false && cfg.neovim or false;
    in
    {
      programs.neovim = {
        enable = lib.mkDefault enableNeovim;
        viAlias = lib.mkIf enableNeovim true;
        vimAlias = lib.mkIf enableNeovim true;
        defaultEditor = false; # Helix is primary editor

        extraPackages = lib.optionals enableNeovim [
          # LSP servers
          pkgs.nil # Nix LSP
          pkgs.lua-language-server
          pkgs.rust-analyzer

          # Formatters
          pkgs.nixpkgs-fmt
        ];
      };
    };
}
