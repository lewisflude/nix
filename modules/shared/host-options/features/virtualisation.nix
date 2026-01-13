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
    enable = mkEnableOption "virtual machines and containers" // {
      example = true;
    };
    docker = mkEnableOption "Docker containers" // {
      example = true;
    };
    podman = mkEnableOption "Podman containers" // {
      example = true;
    };
  };
}
