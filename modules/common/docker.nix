{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    docker
    docker-client
    docker-compose
    docker-credential-helpers
  ];
}
