# Git configuration
# Dendritic pattern: username from config.home.username, useremail from config.programs.git.settings.user.email
# (set in infrastructure/home-manager.nix auto-config module)
{
  config,
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      key = "64CA14D5A2396CC0";
      signByDefault = true;
    };
    # Use new settings format (git.userName deprecated)
    settings = {
      user = {
        name = config.home.username;
        # email is set via programs.git.settings.user.email in auto-config
        signingkey = "64CA14D5A2396CC0";
      };

      init.defaultBranch = "main";
      core.editor = "hx";
      pull.rebase = true;
      push.autoSetupRemote = true;
      push.followTags = true;
      fetch.prune = true;
      fetch.pruneTags = true;
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      diff.algorithm = "histogram";
      diff.colorMoved = "default";
      diff.mnemonicPrefix = true;
      merge.conflictStyle = "zdiff3";
      rebase.autoSquash = true;
      rebase.autoStash = true;
      rebase.updateRefs = true;
      commit.verbose = true;
      help.autocorrect = "prompt";
      rerere.enabled = true;
      column.ui = "auto";
      url."git@github.com:".insteadOf = "https://github.com/";
      commit.gpgsign = true;
      tag.gpgsign = true;
      alias = {
        br = "branch";
        co = "checkout";
        cb = "checkout -b";
        st = "status";
        ci = "commit";
        cm = "commit -m";
        ca = "commit -am";
        dc = "diff --cached";
        amend = "commit --amend -m";
        ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\ %Creset%s%Cblue\ [%cn]%\" --decorate";
        ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\ %Creset%s%Cblue\ [%cn]%\" --decorate --numstat";
        lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        update = "submodule update --init --recursive";
        foreach = "submodule foreach";
      };

      mergetool.nixfmt.cmd = "${pkgs.nixfmt}/bin/nixfmt --mergetool \"$BASE\" \"$LOCAL\" \"$REMOTE\" \"$MERGED\"";
      mergetool.nixfmt.trustExitCode = true;
    };
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      features = "side-by-side line-numbers decorations";
    };
  };
}
