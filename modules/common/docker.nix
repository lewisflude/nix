{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Docker CLI tools for use with Docker Desktop
  environment.systemPackages = with pkgs; [
    docker-client
    docker-compose
    docker-credential-helpers
  ];
}
