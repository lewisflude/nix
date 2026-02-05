# SSH configuration - Dendritic Pattern
# Single file containing NixOS service config and home-manager client config
{ config, ... }:
let
  constants = config.constants;
in
{
  # ===========================================================================
  # NixOS: OpenSSH server configuration
  # ===========================================================================
  flake.modules.nixos.ssh =
    { lib, ... }:
    {
      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PubkeyAuthentication = true;
          PermitEmptyPasswords = false;
          PermitRootLogin = "no";
          Compression = false;
          MaxAuthTries = 3;
          MaxSessions = 10;
          MaxStartups = "10:30:100";
          LoginGraceTime = 30;
          ClientAliveInterval = 30;
          ClientAliveCountMax = 10;
          TCPKeepAlive = false;
          X11Forwarding = false;
          AllowTcpForwarding = true;
          AllowAgentForwarding = true;
          StreamLocalBindUnlink = true;
          PermitTunnel = false;
          UseDns = false;
        };
      };
    };

  # ===========================================================================
  # Home-manager: SSH client configuration
  # ===========================================================================
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
