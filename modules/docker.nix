{ config, lib, pkgs, ... }: {
  # Add Docker to system packages
  environment.systemPackages = with pkgs; [ docker docker-compose ];

  # Configure Docker daemon settings
  launchd.daemons.docker = {
    serviceConfig = {
      Label = "com.docker.docker";
      ProgramArguments = [ "${pkgs.docker}/bin/dockerd" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/var/log/docker.err.log";
      StandardOutPath = "/var/log/docker.out.log";
      # Ensure Docker has the necessary permissions
      UserName = "lewisflude";
      GroupName = "staff";
      # Set working directory
      WorkingDirectory = "/Users/lewisflude";
    };
  };

  # Create Docker daemon configuration directory and set up socket
  system.activationScripts.docker = ''
    # Create Docker configuration directory
    mkdir -p /Users/lewisflude/.docker
    cat > /Users/lewisflude/.docker/daemon.json << EOF
    {
      "debug": true,
      "experimental": true,
      "max-file": 100,
      "hosts": [
        "unix:///var/run/docker.sock",
        "tcp://localhost:2375"
      ]
    }
    EOF
    chown -R lewisflude:staff /Users/lewisflude/.docker

    # Create Docker socket directory
    mkdir -p /var/run
    touch /var/run/docker.sock
    chmod 666 /var/run/docker.sock
    chown lewisflude:staff /var/run/docker.sock
  '';
}
