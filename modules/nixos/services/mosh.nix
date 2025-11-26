{
  # Mosh (mobile shell) - UDP-based SSH alternative for better roaming
  # More resilient to network changes, intermittent connectivity, and roaming
  programs.mosh = {
    enable = true;

    # Automatically open UDP ports 60000-61000 in firewall
    # Mosh uses this range for establishing connections
    openFirewall = true;

    # Enable libutempter for proper utmp/wtmp logging
    # This allows 'who' and 'last' commands to work with mosh sessions
    withUtempter = true;
  };
}
