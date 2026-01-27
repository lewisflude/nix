{ pkgs, lib, ... }:
{
  home.packages = [
    # Essentials (Keep what you actually use daily)
    pkgs.curl
    pkgs.tree
    pkgs.ouch

    # Nix Power Tools (The ones hard to replace with 'comma')
    pkgs.nix-output-monitor
    pkgs.nix-tree
    pkgs.comma
    
    # Modern Nix Dev Flow
    pkgs.nix-init
    pkgs.nurl
    pkgs.nix-diff

    # Workflow
    pkgs.cocogitto
    pkgs.yaml-language-server
  ];
}