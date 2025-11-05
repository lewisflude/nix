{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkBefore mkIf;
  flakePath = "/home/${config.host.username}/.config/nix";
  flakeRef = "${flakePath}#${config.host.hostname}";
in
{
  config = mkIf (config.host ? username && config.host ? hostname) {
    system.autoUpgrade = {
      enable = true;
      flake = flakeRef;
      dates = "Sun *-*-* 08:00:00";
      randomizedDelaySec = "1h";
      persistent = true;
    };

    systemd.services.nixos-upgrade.serviceConfig.ExecStartPre = mkBefore [
      "${config.nix.package.out}/bin/nix flake update --flake ${flakePath}"
    ];
  };
}
