{
  pkgs,
  lib,
  ...
}: let
  cockpit-apps = pkgs.callPackage ../../../pkgs/cockpit-extensions/default.nix {inherit pkgs;};
in {
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        # Allow unencrypted connections since Caddy handles TLS
        AllowUnencrypted = true;

        # Allow connections from your domain and local addresses
        Origins = lib.mkForce "https://localhost:9090 http://localhost:9090 https://jupiter:9090 http://jupiter:9090 https://cockpit.blmt.io http://cockpit.blmt.io";

        # Tell Cockpit to trust the X-Forwarded-Proto header from Caddy
        ProtocolHeader = "X-Forwarded-Proto";

        # Tell Cockpit to trust the X-Forwarded-For header from Caddy
        ForwardedForHeader = "X-Forwarded-For";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    cockpit
    cockpit-apps.podman-containers
  ];
}
