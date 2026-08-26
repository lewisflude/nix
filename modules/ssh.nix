# SSH configuration - Dendritic Pattern
# Single file containing NixOS service config and home-manager client config
{ config, ... }:
let
  inherit (config) constants username;
in
{
  # ===========================================================================
  # NixOS: OpenSSH server configuration
  # ===========================================================================
  flake.modules.nixos.ssh = _: {
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      # openFirewall defaults to true, which is what actually published sshd to
      # the internet: eno2 carries both LAN and router-forwarded WAN traffic, so
      # a globally-open 22 is a WAN-open 22. One 21h boot logged sustained
      # root/ansible/zimbra brute-force attempts and 98 fail2ban bans. Key-only
      # auth meant none could succeed, but the exposure is unnecessary —
      # tailscale0 is in networking.firewall.trustedInterfaces (tailscale.nix),
      # so SSH still works over the tailnet with no port open to the network.
      openFirewall = false;
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
    { pkgs, ... }@hmArgs:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;

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

          # Tailnet addresses, not LAN ones: these aliases have to resolve from
          # anywhere, and neither host advertises subnet routes, so a
          # 192.168.10.x HostName only works while you are on the home LAN.
          "jupiter" = {
            HostName = constants.hosts.jupiter.tailscaleIpv4;
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
            HostName = constants.hosts.mercury.tailscaleIpv4;
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
  # Darwin: Apple's built-in sshd (mercury)
  # ===========================================================================
  # macOS ships its own sshd and its /etc/ssh/sshd_config `Include`s
  # /etc/ssh/sshd_config.d/*. nix-darwin writes a drop-in there
  # (100-nix-darwin.conf) instead of overwriting Apple's OS-owned config, and
  # enabling the service flips on Remote Login via launchd.
  #
  # Keys are served from a root-owned path via AuthorizedKeysCommand
  # (/etc/ssh/nix_authorized_keys.d/%u), which sidesteps macOS StrictModes
  # rejecting a ~/.ssh symlink that resolves into the group-writable Nix store.
  #
  # Crypto is hardened per the ssh-audit macOS guide, using algorithms confirmed
  # available in the OpenSSH 10.x that ships with current macOS (incl. the
  # post-quantum mlkem768x25519-sha256 KEX). Weak ECDSA/DSA host keys are not
  # offered — clients negotiate the ed25519 host key instead.
  flake.modules.darwin.ssh = _: {
    services.openssh = {
      enable = true;
      extraConfig = ''
        Port 22

        # --- Authentication: keys only ---
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        PubkeyAuthentication yes
        PermitEmptyPasswords no
        PermitRootLogin no
        MaxAuthTries 3
        LoginGraceTime 30

        # --- Modern crypto (ssh-audit hardened; OpenSSH 10 on macOS) ---
        HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
        KexAlgorithms mlkem768x25519-sha256,sntrup761x25519-sha512@openssh.com,curve25519-sha256,diffie-hellman-group18-sha512,diffie-hellman-group16-sha512
        Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
        MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com

        # --- Session limits ---
        MaxSessions 10
        MaxStartups 10:30:100
        Compression no

        # iOS SSH clients (Prompt over Tailscale) can be suspended in the
        # background; keep server-side probes permissive so short interruptions
        # do not kill otherwise healthy sessions.
        ClientAliveInterval 60
        ClientAliveCountMax 30
        TCPKeepAlive no

        # --- Forwarding / environment ---
        X11Forwarding no
        AllowTcpForwarding yes
        AllowAgentForwarding yes
        PermitTunnel no
        StreamLocalBindUnlink yes
        UseDNS no
        AcceptEnv PROMPT_LINK_COLS
      '';
    };

    # Declarative authorized keys from the shared source of truth. nix-darwin
    # installs these to /etc/ssh/nix_authorized_keys.d/<user>, read by sshd via
    # AuthorizedKeysCommand — no StrictModes symlink footgun.
    users.users.${username}.openssh.authorizedKeys.keys = constants.authorizedKeys;
  };
}
