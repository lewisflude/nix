# Autobrr Service Module - Dendritic Pattern
# IRC/announce-based release grabbing for *arr stack
# Usage: Import config.flake.modules.nixos.autobrr in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.autobrr =
    { lib, pkgs, ... }:
    let
      inherit (lib) mkDefault;
      secretPath = "/var/lib/autobrr/session-secret";
    in
    {
      services.autobrr = {
        enable = true;
        openFirewall = false;
        secretFile = secretPath;
        settings = {
          host = "127.0.0.1";
          port = constants.ports.services.autobrr;
          checkForUpdates = false;
        };
      };

      systemd.services.autobrr-secret = {
        description = "Generate autobrr session secret";
        wantedBy = [ "multi-user.target" ];
        before = [ "autobrr.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if [ ! -f "${secretPath}" ]; then
            mkdir -p "$(dirname "${secretPath}")"
            ${pkgs.openssl}/bin/openssl rand -hex 32 > "${secretPath}"
            chmod 0400 "${secretPath}"
          fi
        '';
      };

      systemd.services.autobrr = {
        after = [ "autobrr-secret.service" ];
        requires = [ "autobrr-secret.service" ];
        environment.TZ = mkDefault constants.defaults.timezone;
        serviceConfig.UMask = "0002";
      };
    };
}
