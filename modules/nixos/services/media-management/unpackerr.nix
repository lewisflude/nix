{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;

  unpackerrConfig = pkgs.writeText "unpackerr.conf" ''
    [unpackerr]
    debug = false
    quiet = false
    error_stderr = false
    activity = false
    log_queues = "1m"
    log_file = ""
    log_files = 10
    log_file_mb = 10
    interval = "2m"
    start_delay = "1m"
    retry_delay = "5m"
    max_retries = 3
    parallel = 1
    file_mode = "0644"
    dir_mode = "0755"

    [sonarr]
    url = "http://localhost:${toString constants.ports.services.sonarr}"
    paths = ["${cfg.dataPath}/torrents", "${cfg.dataPath}/usenet"]
    protocols = "torrent,usenet"
    timeout = "10s"
    delete_orig = false
    delete_delay = "5m"

    [radarr]
    url = "http://localhost:${toString constants.ports.services.radarr}"
    paths = ["${cfg.dataPath}/torrents", "${cfg.dataPath}/usenet"]
    protocols = "torrent,usenet"
    timeout = "10s"
    delete_orig = false
    delete_delay = "5m"

    [lidarr]
    url = "http://localhost:${toString constants.ports.services.lidarr}"
    paths = ["${cfg.dataPath}/torrents", "${cfg.dataPath}/usenet"]
    protocols = "torrent,usenet"
    timeout = "10s"
    delete_orig = false
    delete_delay = "5m"

    [readarr]
    url = "http://localhost:${toString constants.ports.services.readarr}"
    paths = ["${cfg.dataPath}/torrents", "${cfg.dataPath}/usenet"]
    protocols = "torrent,usenet"
    timeout = "10s"
    delete_orig = false
    delete_delay = "5m"
  '';
in
{
  options.host.services.mediaManagement.unpackerr.enable =
    mkEnableOption "Unpackerr archive extractor"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.unpackerr.enable) {

    environment.systemPackages = [ pkgs.unpackerr ];

    systemd.services.unpackerr = {
      description = "Unpackerr - Archive extractor for *arr apps";
      after = [
        "network.target"
      ]
      ++ optional cfg.radarr.enable "radarr.service"
      ++ optional cfg.sonarr.enable "sonarr.service"
      ++ optional cfg.lidarr.enable "lidarr.service"
      ++ optional cfg.readarr.enable "readarr.service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.unpackerr}/bin/unpackerr -c ${unpackerrConfig}";
        Restart = "on-failure";
        RestartSec = "30s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataPath ];
      };

      environment = {
        TZ = cfg.timezone;
      };
    };
  };
}
