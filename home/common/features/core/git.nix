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
    # Note: GPG signing is disabled by default. Configure per-user if needed.
    # signing = {
    #   key = "YOUR_GPG_KEY_ID";
    #   signByDefault = true;
    # };
    settings = {
      user = {
        name = username;
        email = useremail;
        # signingkey = "YOUR_GPG_KEY_ID";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;

      url."git@github.com:" = {
        insteadOf = "https://github.com/";
      };
      gpg = {
        program = "${pkgs.gnupg}/bin/gpg";
        format = "openpgp";
      };
      # GPG signing disabled by default. Enable per-user if you have a key configured.
      # commit.gpgsign = true;
      # tag.gpgsign = true;
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
