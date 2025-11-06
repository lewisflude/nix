{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkBefore mkIf mkForce;
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

    systemd.services.nixos-upgrade = {
      serviceConfig.ExecStartPre = mkBefore [
        "${config.nix.package.out}/bin/nix flake update --flake ${flakePath}"
      ];
      # Override environment to set NIX_PATH for the service without requiring it globally
      environment.NIX_PATH = mkForce "nixpkgs=flake:nixpkgs";
    };
  };
}
