# Caddy Base Configuration
# Main Caddy service configuration and options
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.host.services.caddy;
in
{
  options.host.services.caddy = {
    enable = mkEnableOption "Caddy web server with reverse proxy configuration" // {
      default = false;
    };

    openFirewall = mkEnableOption "Open firewall ports (80/443) for Caddy" // {
      default = true;
    };

    email = mkOption {
      type = types.str;
      default = "";
      description = "Email address for ACME/Let's Encrypt certificates";
    };
  };

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      inherit (cfg) email;
    };

    # Open firewall for HTTP and HTTPS
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      80
      443
    ];
  };
}
