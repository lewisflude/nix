# User packages and core tooling
# Dendritic pattern: Full implementation as flake.modules.homeManager.userPackages
{ config, ... }:
{
  flake.modules.homeManager.userPackages =
    { pkgs, lib, ... }:
    let
      llmAgentPkgs = pkgs.llmAgents or { };
    in
    {
      home.packages = [
        # Essentials
        pkgs.curl
        pkgs.tree
        pkgs.ouch

        # Nix Power Tools
        pkgs.nh
        pkgs.nix-output-monitor
        pkgs.nix-tree
        pkgs.comma

        # Modern Nix Dev Flow
        pkgs.nix-init
        pkgs.nurl
        pkgs.nix-diff

        # Shell tools
        pkgs.atuin

        # Workflow
        pkgs.cocogitto
        pkgs.yaml-language-server

        # Additional packages
        pkgs.pgcli
        pkgs.cursor-cli
        pkgs.lefthook
      ]
      ++ lib.optionals (llmAgentPkgs ? ccusage) [ llmAgentPkgs.ccusage ]
      ++ lib.optionals (llmAgentPkgs ? coding-agent-search) [ llmAgentPkgs.coding-agent-search ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.libnotify
        pkgs.seahorse
      ];

      programs.htop.enable = true;
      programs.btop.enable = true;
    };
}
