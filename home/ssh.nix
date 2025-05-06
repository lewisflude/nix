{ config, lib, pkgs, ... }: {
  programs.ssh = {
    enable = true;

    # Global SSH settings
    extraConfig = ''
      # Global settings
      Host *
        # Security settings
        AddKeysToAgent yes
        UseKeychain no
        IdentitiesOnly yes
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
        Compression no
        ForwardAgent no
        ForwardX11 no
        ForwardX11Trusted no

        # Connection settings
        ControlMaster auto
        ControlPath ~/.ssh/control/%r@%h:%p
        ControlPersist 10m
    '';

    # Host-specific configurations
    matchBlocks = {
      # GitHub configuration
      "github.com" = {
        hostname = "github.com";
        user = "git";
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = "no";
          IdentitiesOnly = "yes";
        };
      };

      # Example template for other services
      # "example.com" = {
      #   hostname = "example.com";
      #   user = "your-username";
      #   port = 22;
      #   identityFile = "~/.ssh/id_ed25519";
      #   extraOptions = {
      #     AddKeysToAgent = "yes";
      #     UseKeychain = "no";
      #     IdentitiesOnly = "yes";
      #   };
      # };
    };
  };

  # Create SSH control directory
  home.activation.createSshControlDir =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ~/.ssh/control
    '';
}
