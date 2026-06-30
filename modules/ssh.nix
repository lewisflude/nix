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
        # iOS SSH clients can be suspended while Prompt is in the background.
        # Keep server-side probes permissive enough that short app/background
        # interruptions do not kill otherwise healthy sessions.
        ClientAliveInterval = 60;
        ClientAliveCountMax = 30;
        TCPKeepAlive = false;
        AcceptEnv = [ "PROMPT_LINK_COLS" ];
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
    { pkgs, lib, ... }@hmArgs:
    let
      inherit (pkgs.stdenv) isDarwin;

      # The local extra socket (source of forward) — on the machine you're sitting at.
      # isDarwin tells us which host we're building for.
      localExtraSocket =
        if isDarwin then constants.hosts.mercury.gpgAgentExtra else constants.hosts.jupiter.gpgAgentExtra;
    in
    {
      home.file = {
        ".ssh/sockets/.keep".text = "";
      }
      # On Darwin (mercury), Apple's sshd reads ~/.ssh/authorized_keys directly —
      # there is no NixOS openssh.authorizedKeys option. Provision it declaratively
      # from the shared key list so mercury stays in sync with jupiter.
      // lib.optionalAttrs isDarwin {
        ".ssh/authorized_keys".text = lib.concatLines constants.authorizedKeys;
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            AddKeysToAgent = "yes";
            IdentitiesOnly = true;
            HashKnownHosts = true;
            ForwardAgent = false;
            ControlMaster = "auto";
            ControlPath = "~/.ssh/sockets/%r@%h-%p";
            ControlPersist = "600";
            ServerAliveInterval = 15;
            ServerAliveCountMax = 4;
            SendEnv = [
              "TERM"
              "PROMPT_LINK_COLS"
            ];
            TCPKeepAlive = false;
          };

          "192.168.10.1" = {
            RequestTTY = "yes";
            SetEnv.TERM = "vt100";
          };

          "github.com" = {
            User = "git";
          };

          "jupiter" = {
            HostName = constants.hosts.jupiter.ipv4;
            User = hmArgs.config.home.username;
            ForwardAgent = true;
            RemoteForward = [
              {
                bind.address = constants.hosts.jupiter.gpgAgent;
                host.address = localExtraSocket;
              }
            ];
            StreamLocalBindUnlink = true;
          };

          "mercury" = {
            HostName = constants.hosts.mercury.ipv4;
            User = hmArgs.config.home.username;
            ForwardAgent = true;
            RemoteForward = [
              {
                bind.address = constants.hosts.mercury.gpgAgent;
                host.address = localExtraSocket;
              }
            ];
            StreamLocalBindUnlink = true;
          };
        };
      };
    };

  # ===========================================================================
  # Darwin: enable Apple's sshd via nix-darwin (flips Remote Login on)
  # ===========================================================================
  # Apple's sshd is configured via a drop-in that the system sshd_config
  # Includes, so these directives mirror jupiter's hardened NixOS settings
  # (services.openssh.settings above) using equivalent sshd_config syntax.
  flake.modules.darwin.ssh = _: {
    services.openssh = {
      enable = true;
      extraConfig = ''
        Port 22

        PasswordAuthentication no
        KbdInteractiveAuthentication no
        PubkeyAuthentication yes
        PermitEmptyPasswords no
        PermitRootLogin no

        Compression no
        MaxAuthTries 3
        MaxSessions 10
        MaxStartups 10:30:100
        LoginGraceTime 30

        # iOS SSH clients can be suspended while Prompt is in the background.
        # Keep server-side probes permissive enough that short app/background
        # interruptions do not kill otherwise healthy sessions.
        ClientAliveInterval 60
        ClientAliveCountMax 30
        TCPKeepAlive no

        X11Forwarding no
        AllowTcpForwarding yes
        AllowAgentForwarding yes
        PermitTunnel no
        UseDNS no

        StreamLocalBindUnlink yes
        AcceptEnv PROMPT_LINK_COLS
      '';
    };
  };
}
