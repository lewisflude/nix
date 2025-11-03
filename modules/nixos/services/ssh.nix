{
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      # Authentication
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
      PermitEmptyPasswords = false;

      # User access control
      PermitRootLogin = "no";
      # AllowUsers = null; # Allow all users (set to [ "user1" "user2" ] to restrict)
      # AllowGroups = null; # Allow all groups (set to [ "group1" "group2" ] to restrict)

      # Connection limits
      MaxAuthTries = 3;
      MaxSessions = 10;
      MaxStartups = "10:30:100";

      # Timeout settings
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;

      # Security settings
      X11Forwarding = false;
      AllowTcpForwarding = true;
      AllowAgentForwarding = false; # Disable agent forwarding for security
      PermitTunnel = false;

      # DNS and network
      UseDns = true;
      # Banner = "/etc/ssh/banner"; # Optional: Add a banner file for security awareness

      # Protocol and encryption
      # Protocol 2 is the default in modern OpenSSH (no need to specify)
      # Ciphers and MACs are automatically configured with secure defaults
    };
  };
}
