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
    { config, pkgs, ... }:
    let
      isDarwin = pkgs.stdenv.isDarwin;
      homeDir = config.home.homeDirectory;

      # The local extra socket is the source of the forward (on the machine you're sitting at)
      localExtraSocket =
        if isDarwin
        then "${homeDir}/.gnupg/S.gpg-agent.extra"
        else "/run/user/1000/gnupg/S.gpg-agent.extra";

      # The remote agent socket is the target (on the machine you're SSHing into)
      remoteAgentSocket = {
        linux = "/run/user/1000/gnupg/S.gpg-agent";
        darwin = "${homeDir}/.gnupg/S.gpg-agent";
      };
    in
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
                bind.address = remoteAgentSocket.linux;
                host.address = localExtraSocket;
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
                bind.address = remoteAgentSocket.darwin;
                host.address = localExtraSocket;
              }
            ];
            extraOptions.StreamLocalBindUnlink = "yes";
          };
        };
      };
    };

  # ===========================================================================
  # Darwin: SSH server GPG forwarding support
  # ===========================================================================
  flake.modules.darwin.ssh =
    { ... }:
    {
      environment.etc."ssh/sshd_config.d/200-gpg-forwarding.conf".text = ''
        StreamLocalBindUnlink yes
      '';
    };
}
