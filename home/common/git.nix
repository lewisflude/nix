{
  username,
  useremail,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      key = "48B34CF9C735A6AE";
      signByDefault = true;
    };
    settings = {
      user = {
        name = username;
        email = useremail;
        signingkey = "48B34CF9C735A6AE";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      gpg = {
        program = "${pkgs.gnupg}/bin/gpg";
        format = "openpgp";
      };
      commit.gpgsign = true;
      tag.gpgsign = true;
      alias = {
        br = "branch";
        co = "checkout";
        st = "status";
        ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\ %Creset%s%Cblue\ [%cn]%\" --decorate";
        ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\ %Creset%s%Cblue\ [%cn]%\" --decorate --numstat";
        cm = "commit -m";
        ca = "commit -am";
        dc = "diff --cached";
        amend = "commit --amend -m";
        update = "submodule update --init --recursive";
        foreach = "submodule foreach";
      };
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
