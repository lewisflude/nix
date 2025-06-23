{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    nvidia-docker
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
          default-runtime = "nvidia";
          runtimes.nvidia = {
            path = "nvidia-container-runtime";
            runtimeArgs = [ ];
          };
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
    wantedBy = [ "multi-user.target" ];
    before = [ "docker.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml";
      Type = "oneshot";
    };
  };

  users.users.lewis.extraGroups = [ "docker" ];
}
