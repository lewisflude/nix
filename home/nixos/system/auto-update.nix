{
  pkgs,
  lib,
  config,
  ...
}: {
  systemd.user = {
    services.nix-update = {
      Unit = {
        Description = "NixOS system update";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "nix-update-script" ''
          set -euo pipefail
          SYSTEM_UPDATE_BIN=${lib.escapeShellArg "${config.home.profileDirectory}/bin/system-update"}
          if [ ! -x "$SYSTEM_UPDATE_BIN" ]; then
            echo "system-update not found at $SYSTEM_UPDATE_BIN" >&2
            exit 1
          fi
          ${pkgs.sudo}/bin/sudo -E "$SYSTEM_UPDATE_BIN" --inputs
        ''}";
      };
    };
    timers.nix-update = {
      Unit = {
        Description = "Weekly NixOS system update";
      };
      Timer = {
        OnCalendar = "Sun *-*-* 08:00:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
