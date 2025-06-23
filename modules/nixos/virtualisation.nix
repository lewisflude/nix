{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    nvidia-docker
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
          log-driver = "journald";
          default-runtime = "nvidia";

          dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          registry-mirrors = [ "https://mirror.gcr.io" ];
          cdi-spec-dirs = [ "/var/run/cdi" ];
        };
      };
    };
  };

  systemd.services.nvidia-cdi = {
    wantedBy = [ "docker.service" ];
    before = [ "docker.service" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/run/cdi";
      ExecStart = "${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml";
      Type = "oneshot";
    };
  };

  users.users.lewis.extraGroups = [ "docker" ];
}
