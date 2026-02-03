# Lutris Gaming Module - Dendritic Pattern
# Open source gaming platform
{ ... }:
{
  flake.modules.nixos.lutris = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.lutris ];
  };
}
