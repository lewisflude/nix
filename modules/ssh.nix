# SSH configuration - Dendritic Pattern
# Single file containing NixOS service config and home-manager client config
{ config, ... }:
let
  inherit (config) constants;
in
{
  # ===========================================================================
  # NixOS: OpenSSH server configuration
  # ===========================================================================
  flake.modules.nixos.ssh = _: {
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
        ClientAliveCountMax = 3;
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
    { pkgs, ... }@hmArgs:
    let
      inherit (pkgs.stdenv) isDarwin;

      # The local extra socket (source of forward) — on the machine you're sitting at.
      # isDarwin tells us which host we're building for.
      localExtraSocket =
        if isDarwin then constants.hosts.mercury.gpgAgentExtra else constants.hosts.jupiter.gpgAgentExtra;
    in
    {
      home.file.".ssh/sockets/.keep".text = "";

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            addKeysToAgent = "yes";
            identitiesOnly = true;
            hashKnownHosts = true;
            forwardAgent = false;
            controlMaster = "auto";
            controlPath = "~/.ssh/sockets/%r@%h-%p";
            controlPersist = "600";
            serverAliveInterval = 15;
            serverAliveCountMax = 4;
            sendEnv = [ "TERM" ];
            extraOptions = {
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
            user = hmArgs.config.home.username;
            forwardAgent = true;
            remoteForwards = [
              {
                bind.address = constants.hosts.jupiter.gpgAgent;
                host.address = localExtraSocket;
              }
            ];
            extraOptions.StreamLocalBindUnlink = "yes";
          };

          "mercury" = {
            hostname = constants.hosts.mercury.ipv4;
            user = hmArgs.config.home.username;
            forwardAgent = true;
            remoteForwards = [
              {
                bind.address = constants.hosts.mercury.gpgAgent;
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
  flake.modules.darwin.ssh = _: {
    environment.etc."ssh/sshd_config.d/200-gpg-forwarding.conf".text = ''
      StreamLocalBindUnlink yes
    '';
  };
}
