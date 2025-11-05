# Test configuration for container services
# This enables only a minimal subset for testing
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.host.features.containers.test = {
    enable = mkEnableOption "test mode - enables only minimal containers";
  };

  config = mkIf config.host.features.containers.test.enable {
    # Enable containers with minimal setup
    host.features.containers = {
      enable = true;

      # Disable full stacks
      mediaManagement.enable = false;
      productivity.enable = false;
    };

    # Just enable a single test container to verify Podman works
    virtualisation.oci-containers.containers = {
      # Simple test container - nginx web server
      test-nginx = {
        image = "nginx:alpine";
        ports = [ "8888:80" ];
        volumes = [
          "/tmp/test-container:/usr/share/nginx/html:ro"
        ];
      };

      # Test container - simple busybox
      test-busybox = {
        image = "busybox:latest";
        cmd = [
          "sh"
          "-c"
          "echo 'Container test successful!' && sleep 3600"
        ];
      };
    };

    # Create test file
    systemd.tmpfiles.rules = [
      "d /tmp/test-container 0755 root root -"
      "f /tmp/test-container/index.html 0644 root root - <!DOCTYPE html><html><body><h1>NixOS Container Test Works!</h1></body></html>"
    ];
  };
}
