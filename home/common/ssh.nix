_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
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

        extraOptions = {
          StrictHostKeyChecking = "yes";
        };
      };
    };
  };
}
