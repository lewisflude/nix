{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.services.mediaManagement;
  vpnEnabled = cfg.enable && cfg.qbittorrent.enable && cfg.qbittorrent.vpn.enable;
  webUIPort = cfg.qbittorrent.webUI.port or 8080;
in
{
  config = mkIf (vpnEnabled && cfg.qbittorrent.enable) {

    services.nginx = {
      enable = true;
      virtualHosts."qbittorrent-proxy" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = webUIPort;
          }
        ];
        locations."/" = {
          proxyPass = "http://192.168.15.1:${toString webUIPort}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
          '';
        };
      };
    };

    systemd.services.nginx = {
      after = [ "network.target" ];
    };
  };
}
