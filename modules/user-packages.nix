# User packages and core tooling
# Dendritic pattern: Full implementation as flake.modules.homeManager.userPackages
# Note: General CLI tools are in cli-apps.nix, this module is for user-specific packages
_: {
  flake.modules.homeManager.userPackages =
    { pkgs, lib, ... }:
    let
      llmAgentPkgs = pkgs.llmAgents or { };
    in
    {
      home.packages = [
        # Nix Power Tools
        pkgs.nh

        # Database clients
        pkgs.pgcli

        # Development tools
        pkgs.cursor-cli
      ]
      ++ lib.optionals (llmAgentPkgs ? ccusage) [ llmAgentPkgs.ccusage ]
      ++ lib.optionals (llmAgentPkgs ? coding-agent-search) [ llmAgentPkgs.coding-agent-search ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        pkgs.libnotify
        pkgs.seahorse
      ];
    };
}
