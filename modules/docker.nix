{ config, lib, pkgs, ... }: {
  # Add Docker to system packages
  environment.systemPackages = with pkgs; [ docker docker-compose ];

  # Configure Docker daemon settings
  launchd.daemons.docker = {
    serviceConfig = {
      Label = "com.docker.docker";
      ProgramArguments =
        [ "${pkgs.docker}/bin/dockerd" "--config" "/etc/docker/daemon.json" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/var/log/docker.err.log";
      StandardOutPath = "/var/log/docker.out.log";
      # Ensure Docker has the necessary permissions
      UserName = "lewisflude";
      GroupName = "staff";
    };
  };

  # Create Docker daemon configuration
  environment.etc."docker/daemon.json".text = lib.generators.toJSON { } {
    "max-file" = 100;
    experimental = true;
    # Add macOS-specific settings
    "debug" = true;
    "hosts" = [ "unix:///var/run/docker.sock" "tcp://localhost:2375" ];
  };
}
