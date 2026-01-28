# Virtualisation Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  virtualisation = {
    enable = mkEnableOption "virtual machines and containers";
    docker = mkEnableOption "Docker containers";
    podman = mkEnableOption "Podman containers";
  };
}
