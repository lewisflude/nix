{
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      # Authentication settings
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
      PermitEmptyPasswords = false;
      PermitRootLogin = "no";

      # Performance optimizations
      # Disable compression - CPU intensive and slows down fast networks
      # Compression is only beneficial on very slow connections
      Compression = false;

      # Connection limits
      MaxAuthTries = 3;
      MaxSessions = 10;
      # MaxStartups: start:rate:full
      # Allow 10 new connections, then rate limit at 30:50%, reject at 100
      MaxStartups = "10:30:100";

      # Login grace time - fail fast on authentication attempts
      # Reduced from default 120s to 30s to avoid hanging connections
      LoginGraceTime = 30;

      # Keepalive settings
      # Send keepalive probe every 30 seconds
      ClientAliveInterval = 30;
      # Allow 10 missed responses before terminating (5 minutes total)
      # This is more lenient to handle network issues, NAT, and firewalls
      ClientAliveCountMax = 10;
      # Use SSH-level keepalive instead of TCP keepalive
      # SSH keepalive is more reliable through NAT/firewalls
      TCPKeepAlive = false;

      # Forwarding settings
      X11Forwarding = false;
      AllowTcpForwarding = true;
      AllowAgentForwarding = false;
      PermitTunnel = false;

      # DNS settings - disable to prevent delays
      UseDns = false;

      # Note: Algorithm settings (KexAlgorithms, Ciphers, MACs) are not explicitly set
      # Modern OpenSSH already uses optimal, fast algorithms by default
      # The main performance improvements come from:
      # - Disabling compression (Compression = false)
      # - Disabling DNS lookups (UseDns = false)
      # - Fast login grace time (LoginGraceTime = 30)
    };
  };
}
