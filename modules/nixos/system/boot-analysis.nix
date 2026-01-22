{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.services.boot-analysis;
in
{
  options.services.boot-analysis = {
    enable = mkEnableOption "automatic boot performance analysis" // {
      default = false;
    };

    delay = mkOption {
      type = types.str;
      default = "5min";
      description = "How long to wait after boot before running analysis";
    };
  };

  config = mkIf cfg.enable {
    systemd.timers.boot-analysis = {
      description = "Boot Performance Analysis Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = cfg.delay;
        Unit = "boot-analysis.service";
      };
    };

    systemd.services.boot-analysis = {
      description = "Analyze Boot Performance";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "boot-analysis" ''
          #!/bin/sh
          echo "========================================" >&2
          echo "Boot Performance Analysis" >&2
          echo "========================================" >&2
          echo "" >&2

          echo "=== Boot Time ===" >&2
          ${pkgs.systemd}/bin/systemd-analyze --no-pager || true
          echo "" >&2

          echo "=== Critical Chain ===" >&2
          ${pkgs.systemd}/bin/systemd-analyze critical-chain --no-pager || true
          echo "" >&2

          echo "=== Slowest Units ===" >&2
          ${pkgs.systemd}/bin/systemd-analyze blame --no-pager | ${pkgs.coreutils}/bin/head -n 20 || true
          echo "" >&2

          echo "========================================" >&2
        ''}";

        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "boot-analysis";

        # Security
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateNetwork = true;
      };
    };
  };
}
