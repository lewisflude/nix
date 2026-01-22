{ config, ... }:
let
  constants = import ../../../../lib/constants.nix;
in
{
  programs.ssh = {
    enable = true;
    # Disable default config to avoid deprecation warning
    # We explicitly set all needed options in matchBlocks
    enableDefaultConfig = false;
    # Performance optimizations applied to all hosts via extraConfig
    matchBlocks = {
      "*" = {
        # Add keys to agent automatically
        addKeysToAgent = "yes";

        # Send terminal environment variables (fixes backspace on embedded devices)
        sendEnv = [ "TERM" ];

        # Keepalive settings to prevent session termination
        # Prevents NAT timeout, firewall drops, and idle disconnections
        extraOptions = {
          # Send keepalive probe every 15 seconds
          ServerAliveInterval = "15";
          # Allow 4 missed responses before terminating (60 seconds total)
          ServerAliveCountMax = "4";
          # Use SSH-level keepalive instead of TCP keepalive
          # SSH keepalive is more reliable through NAT/firewalls
          TCPKeepAlive = "no";
        };
      };

      "192.168.10.1" = {
        # Use simple terminal type for embedded devices (routers, switches, etc.)
        extraOptions = {
          RequestTTY = "yes";
          SetEnv = "TERM=vt100";
        };
      };

      "github.com" = {
        user = "git";
        # Use agent-provided keys (YubiKey OpenPGP via GPG agent)
        # Without identitiesOnly, SSH will query the agent for available keys
        # and offer them to GitHub. This allows YubiKey keys to work.
      };

      # Internal hosts
      "jupiter" = {
        hostname = constants.hosts.jupiter.ipv4;
        user = config.home.username;
      };

      "mercury" = {
        hostname = constants.hosts.mercury.ipv4;
        user = config.home.username;
      };
    };
  };
}
