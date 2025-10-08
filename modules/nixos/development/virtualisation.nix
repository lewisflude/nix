{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
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
      backend = "podman";
    };
    podman = {
      enable = true;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = true;
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
