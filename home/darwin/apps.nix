{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # macOS-specific packages
    anchor
    betterdisplay
    firefox-devedition
    insomnia
    pgadmin4
    raycast
    slack
    tableplus
    dockutil
  ];
}