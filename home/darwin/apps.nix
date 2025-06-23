{ pkgs, ... }:
{
  home.packages = with pkgs; [
    tableplus
    jetbrains.datagrip
    dbeaver-bin
  ];
}
