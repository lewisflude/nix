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

      MaxAuthTries = 3;
      MaxSessions = 10;
      MaxStartups = "10:30:100";

      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;

      X11Forwarding = false;
      AllowTcpForwarding = true;
      AllowAgentForwarding = false;
      PermitTunnel = false;

      UseDns = true;

    };
  };
}
