{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.security;
in
{
  config = mkIf (cfg.enable && cfg.fail2ban) {
    services.fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        maxtime = "168h"; # 1 week max ban
        factor = "2";
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

        # Caddy web server protection (optional - uncomment if needed)
        # caddy-auth = {
        #   settings = {
        #     enabled = true;
        #     port = "http,https";
        #     filter = "caddy-auth";
        #     maxretry = 10;
        #     findtime = 600;
        #     bantime = 3600;
        #   };
        # };
      };
    };

    # Ensure firewall allows fail2ban to work
    networking.firewall.enable = true;

    # Optional: Add custom filter for Caddy (create if needed)
    # environment.etc."fail2ban/filter.d/caddy-auth.conf".text = ''
    #   [Definition]
    #   failregex = ^.* "(?:GET|POST) .* HTTP/.*" (401|403) .*$
    #   ignoreregex =
    # '';
  };
}
