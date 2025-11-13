_: {
  programs.ssh = {
    enable = true;
    # Disable default config to avoid deprecation warning
    # We explicitly set all needed options in matchBlocks
    enableDefaultConfig = false;
    # Performance optimizations applied to all hosts via extraConfig
    matchBlocks = {
      "*" = {
        # Use only explicitly configured keys (faster authentication)
        # Prevents SSH from trying all keys in ~/.ssh/
        identitiesOnly = true;
        identityFile = [ "~/.ssh/id_ed25519" ];

        # Add keys to agent automatically
        addKeysToAgent = "yes";

        # Send terminal environment variables (fixes backspace on embedded devices)
        sendEnv = [ "TERM" ];
      };

      "192.168.1.1" = {
        # Use simple terminal type for embedded devices (routers, switches, etc.)
        extraOptions = {
          RequestTTY = "yes";
          SetEnv = "TERM=vt100";
        };
      };

      "github.com" = {
        user = "git";
      };
    };
  };
}
