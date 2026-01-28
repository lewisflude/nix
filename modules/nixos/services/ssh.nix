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
      AllowAgentForwarding = false;
      PermitTunnel = false;

      UseDns = false;
    };
  };
}
