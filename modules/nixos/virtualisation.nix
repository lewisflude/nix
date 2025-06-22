{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
  ];
  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
      storageDriver = "overlay2";
      daemon = {
        settings = {
          experimental = true;
          features.cdi = true;
          live-restore = true;
          log-driver = "journald";
          dns = [ "1.1.1.1" "8.8.8.8" ];
          registry-mirrors = [ "https://mirror.gcr.io" ];
          cdi-spec-dirs = [ "/var/run/cdi" ];
        };
      };
    };
  };

  users.users.lewis.extraGroups = [ "docker" ];
}
