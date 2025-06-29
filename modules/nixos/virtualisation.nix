{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    nvidia-docker
    docker-credential-helpers
  ];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "ens3";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };

  virtualisation = {
    oci-containers = {
      backend = "docker";
    };
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
