# Fail2ban Service Module - Dendritic Pattern
# Intrusion prevention system with jail configuration
# Usage: Import flake.modules.nixos.fail2ban in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.fail2ban =
    { lib, ... }:
    let
      inherit (lib) mkDefault;
    in
    {
      services.fail2ban = {
        enable = true;
        maxretry = mkDefault 3;
        bantime = mkDefault "1h";
        bantime-increment = {
          enable = mkDefault true;
          maxtime = mkDefault "168h"; # 1 week max ban
          factor = mkDefault "2";
        };

        jails = {
          # SSH protection
          sshd = {
            settings = {
              enabled = true;
              port = "22";
              filter = "sshd";
              maxretry = 3;
              findtime = 600; # 10 minutes
              bantime = 3600; # 1 hour
            };
          };

          # Eternal Terminal protection
          eternal-terminal = {
            settings = {
              enabled = true;
              port = toString constants.ports.services.eternalTerminal;
              filter = "sshd"; # Uses same auth mechanism as SSH
              maxretry = 5;
              findtime = 600;
              bantime = 3600;
            };
          };

          # Caddy web server protection - auth failures
          caddy-auth = {
            settings = {
              enabled = true;
              port = "http,https";
              filter = "caddy-auth";
              maxretry = 10;
              findtime = 600; # 10 minutes
              bantime = 3600; # 1 hour
            };
          };

          # Caddy exploit protection - aggressive ban for exploit attempts
          caddy-exploit = {
            settings = {
              enabled = true;
              port = "http,https";
              filter = "caddy-exploit";
              maxretry = 2; # Ban after 2 exploit attempts
              findtime = 3600; # 1 hour window
              bantime = 86400; # 24 hour ban
            };
          };
        };
      };

      # Ensure firewall allows fail2ban to work
      networking.firewall.enable = mkDefault true;

      # Fail2ban filters for Caddy
      environment.etc."fail2ban/filter.d/caddy-auth.conf".text = ''
        [Definition]
        failregex = ^.*"remote_ip":"<HOST>".*"status":(401|403).*$
        ignoreregex =
      '';

      environment.etc."fail2ban/filter.d/caddy-exploit.conf".text = ''
        [Definition]
        # Ban on exploit patterns: CVE boundaries, malicious headers, path traversal
        failregex = ^.*"remote_ip":"<HOST>".*("bissa_cve_boundary"|"Next-Action"|"WebKitFormBoundary.*NiggersTongue"|"\.\.\/"|"\.env"|"eval\(").*$
        ignoreregex =
      '';
    };
}
