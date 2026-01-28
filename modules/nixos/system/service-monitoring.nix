{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.services.systemd-monitoring;
in
{
  options.services.systemd-monitoring = {
    enable = mkEnableOption "systemd service failure monitoring" // {
      default = true;
    };

    criticalServices = mkOption {
      type = types.listOf types.str;
      default = [
        "qbittorrent.service"
        "home-assistant.service"
        "protonvpn-portforward.service"
      ];
      description = "Services to monitor for failures";
    };
  };

  config = mkIf cfg.enable {
    systemd.services = lib.mkMerge [
      {
        "notify-failure@" = {
          description = "Log failure for %i";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "notify-failure" ''
              UNIT="$1"
              echo "========================================" >&2
              echo "CRITICAL: Service $UNIT has failed" >&2
              echo "========================================" >&2
              ${pkgs.systemd}/bin/systemctl status "$UNIT" --no-pager || true
              echo "========================================" >&2
              ${pkgs.systemd}/bin/journalctl -u "$UNIT" -n 50 --no-pager || true
              echo "========================================" >&2
            ''} %i";
            StandardOutput = "journal";
            StandardError = "journal";
            SyslogIdentifier = "service-failure";
          };
        };
      }

      (lib.mkMerge (
        map (serviceName: {
          ${serviceName}.unitConfig.OnFailure = "notify-failure@%n.service";
        }) cfg.criticalServices
      ))
    ];
  };
}
