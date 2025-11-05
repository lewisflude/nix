{ pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    package = pkgs.openssh.override { withSecurityKey = true; };
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%h:%p";
        controlPersist = "10m";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = false;
        hashKnownHosts = true;
        extraOptions = {
          PKCS11Provider = "none";
          StrictHostKeyChecking = "accept-new";
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ConnectTimeout = "10";
          ConnectionAttempts = "3";
          VisualHostKey = "yes";
        };
      };
      "github.com" = {
        identitiesOnly = true;
        forwardAgent = false;
        user = "git";
        # GitHub's SSH fingerprints - these are well-known and safe to verify
        extraOptions = {
          StrictHostKeyChecking = "yes";
        };
      };
    };
  };
}
