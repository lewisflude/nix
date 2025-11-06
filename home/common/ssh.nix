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
        identitiesOnly = false;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = false;
        hashKnownHosts = true;
        extraConfig = ''
          StrictHostKeyChecking accept-new
          UserKnownHostsFile ~/.ssh/known_hosts
          ConnectTimeout 10
          ConnectionAttempts 3
          VisualHostKey yes
        '';
      };
      "github.com" = {
        identitiesOnly = false;
        forwardAgent = false;
        user = "git";
        extraConfig = "StrictHostKeyChecking yes";
      };
    };
  };
}
