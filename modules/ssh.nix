# SSH configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.ssh
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.homeManager.ssh =
    { config, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            addKeysToAgent = "yes";
            sendEnv = [ "TERM" ];
            extraOptions = {
              ServerAliveInterval = "15";
              ServerAliveCountMax = "4";
              TCPKeepAlive = "no";
            };
          };

          "192.168.10.1" = {
            extraOptions = {
              RequestTTY = "yes";
              SetEnv = "TERM=vt100";
            };
          };

          "github.com" = {
            user = "git";
          };

          "jupiter" = {
            hostname = constants.hosts.jupiter.ipv4;
            user = config.home.username;
            forwardAgent = true;
            remoteForwards = [
              {
                bind.address = "/run/user/1000/gnupg/S.gpg-agent";
                host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
              }
            ];
            extraOptions.StreamLocalBindUnlink = "yes";
          };

          "mercury" = {
            hostname = constants.hosts.mercury.ipv4;
            user = config.home.username;
            forwardAgent = true;
            remoteForwards = [
              {
                bind.address = "/run/user/1000/gnupg/S.gpg-agent";
                host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
              }
            ];
            extraOptions.StreamLocalBindUnlink = "yes";
          };
        };
      };
    };
}
