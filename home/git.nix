{ username, useremail, ... }:
{
  programs.git = {
    enable = true;
    userName = username;
    userEmail = useremail;
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
    signing = {
      key = "DBAEF83F";
      format = "openpgp";
      signByDefault = true;
    };

    delta = {
      enable = true;
    };
    aliases = {
      br = "branch";
      co = "checkout";
      st = "status";
      ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
      ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
      cm = "commit -m";
      ca = "commit -am";
      dc = "diff --cached";
      amend = "commit --amend -m";
      update = "submodule update --init --recursive";
      foreach = "submodule foreach";
    };
  };
}
