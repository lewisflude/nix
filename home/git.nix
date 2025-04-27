{ username, useremail, ... }: {
  programs.git = {
    enable = true;
    userName = username;
    userEmail = useremail;
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };
}
