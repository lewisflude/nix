# User packages
# Dendritic pattern: Uses pkgs.llmAgents.* from overlay (provided by llm-agents.nix)
{
  pkgs,
  lib,
  ...
}:
let
  # LLM agent packages from overlay (see overlays/default.nix)
  llmAgentPkgs = pkgs.llmAgents or { };
in
{
  home.packages = [
    # Note: coreutils, libnotify, tree, nix-tree, nix-du, yaml-language-server,
    # gnutar, and gzip are handled in core-tooling.nix
    # Note: cachix is handled via programs.cachix in cachix.nix
    # Note: yq is handled via programs.yq in yq.nix
    # Note: sops is handled in features/security/default.nix
    # Note: nx is handled in core-tooling.nix
    # Note: musescore is installed via Homebrew cask (modules/darwin/apps.nix)
    # to avoid duplicate entries in Spotlight/Launchpad
    # Note: claude-code is handled via programs.claude-code in claude-code.nix
    # Note: gemini-cli is handled via programs.gemini-cli in gemini-cli.nix
    pkgs.pgcli
    pkgs.cursor-cli # provides cursor-agent binary
    pkgs.lefthook # Git hooks manager

    # AI coding agent tools from llm-agents.nix (via overlay)
  ]
  ++ lib.optionals (llmAgentPkgs ? ccusage) [
    # ccusage: Usage analysis tool for Claude Code sessions
    llmAgentPkgs.ccusage
  ]
  ++ lib.optionals (llmAgentPkgs ? coding-agent-search) [
    # coding-agent-search: TUI to search coding agent history
    llmAgentPkgs.coding-agent-search
  ]
  # Linux-only packages
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.seahorse # GNOME password and encryption key manager (PGP/GPG GUI)
  ];

  programs.htop.enable = true;
  programs.btop.enable = true;
}
