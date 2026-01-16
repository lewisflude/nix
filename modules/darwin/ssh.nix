_: {
  services.openssh = {
    enable = true;

    # nix-darwin uses extraConfig for SSH settings (no structured settings option)
    # Applied security and performance optimizations matching NixOS SSH config
    extraConfig = ''
      # Authentication settings
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      PubkeyAuthentication yes
      PermitEmptyPasswords no
      PermitRootLogin no

      # Performance optimizations
      # Disable compression - CPU intensive and slows down fast networks
      Compression no

      # Connection limits
      MaxAuthTries 3
      MaxSessions 10
      # MaxStartups: start:rate:full
      # Allow 10 new connections, then rate limit at 30:50%, reject at 100
      MaxStartups 10:30:100

      # Login grace time - fail fast on authentication attempts
      LoginGraceTime 30

      # Keepalive settings
      # Send keepalive probe every 30 seconds
      ClientAliveInterval 30
      # Allow 10 missed responses before terminating (5 minutes total)
      ClientAliveCountMax 10
      # Use SSH-level keepalive instead of TCP keepalive
      TCPKeepAlive no

      # Forwarding settings
      X11Forwarding no
      AllowTcpForwarding yes
      AllowAgentForwarding no
      PermitTunnel no

      # DNS settings - disable to prevent delays
      UseDns no
    '';
  };
}
