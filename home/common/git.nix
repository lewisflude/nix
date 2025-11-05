{
  username,
  useremail,
  pkgs,
  ...
}:
{
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
      # Automatically use SSH for GitHub URLs
      url."git@github.com:" = {
        insteadOf = "https://github.com/";
      };
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
      # Configure nixfmt as git mergetool for automatic formatting conflict resolution
      # Usage: git mergetool -t nixfmt <file>
      mergetool.nixfmt = {
        cmd = "${pkgs.nixfmt-rfc-style}/bin/nixfmt-rfc-style --mergetool \"$BASE\" \"$LOCAL\" \"$REMOTE\" \"$MERGED\"";
        trustExitCode = true;
      };
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
