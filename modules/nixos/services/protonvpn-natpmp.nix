{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.services.protonvpn-natpmp;
in
{
  options.services.protonvpn-natpmp = {
    enable = mkEnableOption "ProtonVPN NAT-PMP port forwarding service";
  };

  config = mkIf cfg.enable {
    systemd.services.protonvpn-natpmp = {
      description = "ProtonVPN NAT-PMP Port Forwarding";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do ${pkgs.natpmp}/bin/natpmpc -g 10.2.0.1 -a 1 62000 tcp 3600; sleep 45; done'";
        Restart = "always";
      };
    };
  };
}
