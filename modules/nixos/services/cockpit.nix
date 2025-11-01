{ }:
{
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;
    # Allow connections from your domain and local addresses
    allowed-origins = [
      "https://localhost:9090"
      "http://localhost:9090"
      "https://jupiter:9090"
      "http://jupiter:9090"
      "https://cockpit.blmt.io"
      "http://cockpit.blmt.io"
    ];
    settings = {
      WebService = {
        # Allow unencrypted connections since Caddy handles TLS
        AllowUnencrypted = true;

        # Tell Cockpit to trust the X-Forwarded-Proto header from Caddy
        ProtocolHeader = "X-Forwarded-Proto";

        # Tell Cockpit to trust the X-Forwarded-For header from Caddy
        ForwardedForHeader = "X-Forwarded-For";
      };
    };
  };

  # Optional: Install Cockpit Podman extension for container management
  # environment.systemPackages = with pkgs; [
  #   cockpit
  #   cockpit-apps.podman-containers
  # ];
}
