{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    nvidia-docker
    docker-credential-helpers
  ];
  virtualisation = {
    docker = {
      package = pkgs.docker_28;
      enable = true;
      enableOnBoot = true;
      storageDriver = "overlay2";
      daemon = {
        settings = {
          experimental = true;
          log-driver = "journald";
          registry-mirrors = [ "https://mirror.gcr.io" ];
        };
      };
    };
  };

  users.users.lewis.extraGroups = [ "docker" ];
}
