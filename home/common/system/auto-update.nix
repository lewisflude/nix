{ pkgs, config, ... }: {
  systemd.user = {
    services.nix-update = {
      Unit = {
        Description = "NixOS system update";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "nix-update-script" ''
          #!/bin/sh
          set -e
          ${pkgs.sudo}/bin/sudo -E ${config.home.homeDirectory}/.dotfiles/home-manager/modules/scripts/bin/system-update --inputs
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
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
