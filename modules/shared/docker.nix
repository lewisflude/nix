{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    docker-client
    docker-compose
    docker-credential-helpers
  ];
}
