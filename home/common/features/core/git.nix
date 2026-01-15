{
  username,
  useremail,
  pkgs,
  themeLib,
  ...
}:
let
  # Generate dark theme for git diff colors
  theme = themeLib.generateTheme "dark" { };
in
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

      # === Core Settings ===
      init.defaultBranch = "main";
      core.editor = "hx"; # Helix editor
      pull.rebase = true; # Keep history linear and clean

      # === Modern Git Best Practices (2025) ===
      # Based on Git core developers' recommendations
      # Source: https://blog.gitbutler.com/how-git-core-devs-configure-git

      # Push configuration
      push.autoSetupRemote = true; # No more "git push --set-upstream"
      push.followTags = true; # Push local tags automatically

      # Fetch optimization
      fetch.prune = true; # Remove deleted remote branches locally
      fetch.pruneTags = true; # Remove deleted remote tags

      # Branch and tag management
      branch.sort = "-committerdate"; # Sort branches by recent commits first
      tag.sort = "version:refname"; # Sort tags semantically

      # Diff improvements
      diff = {
        algorithm = "histogram"; # Modern diff algorithm (better than Myers)
        colorMoved = "default"; # Highlight moved code blocks
        mnemonicPrefix = true; # Show context (i/w/c) instead of a/b
      };

      # Merge configuration
      merge.conflictStyle = "zdiff3"; # Show base, yours, and theirs in conflicts

      # Rebase improvements
      rebase = {
        autoSquash = true; # Auto-squash fixup commits
        autoStash = true; # Auto-stash changes before rebasing
        updateRefs = true; # Update stacked references during rebase
      };

      # Commit configuration
      commit.verbose = true; # Show full diff when writing commit messages

      # Help configuration
      help.autocorrect = "prompt"; # Suggest corrections for mistyped commands

      # Reuse recorded conflict resolutions
      rerere.enabled = true;

      # UI improvements
      column.ui = "auto"; # Display branches in columns

      # === Security & Authentication ===
      url."git@github.com:" = {
        insteadOf = "https://github.com/";
      };

      # GPG configuration
      gpg = {
        program = "${pkgs.gnupg}/bin/gpg";
        format = "openpgp";
      };
      # GPG signing disabled by default. Enable per-user if you have a key configured.
      # commit.gpgsign = true;
      # tag.gpgsign = true;

      # === Aliases ===
      alias = {
        # Basic shortcuts
        br = "branch";
        co = "checkout";
        cb = "checkout -b";
        st = "status";
        ci = "commit";
        cm = "commit -m";
        ca = "commit -am";
        dc = "diff --cached";
        amend = "commit --amend -m";

        # Log visualization - simple format
        ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\ %Creset%s%Cblue\ [%cn]%\" --decorate";
        ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\ %Creset%s%Cblue\ [%cn]%\" --decorate --numstat";

        # Log visualization - graph format (recommended)
        lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";

        # Utility aliases
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        update = "submodule update --init --recursive";
        foreach = "submodule foreach";
      };

      # Nix formatter for merge conflicts
      mergetool.nixfmt = {
        cmd = "${pkgs.nixfmt}/bin/nixfmt --mergetool \"$BASE\" \"$LOCAL\" \"$REMOTE\" \"$MERGED\"";
        trustExitCode = true;
      };
    };

    # === Multiple Identity Configuration (Optional) ===
    # Uncomment and configure if you need different git identities for work/personal repos
    # includes = [
    #   {
    #     condition = "gitdir:~/dev/work/";
    #     contents = {
    #       user.email = "work@company.com";
    #       user.signingkey = "WORK_GPG_KEY_ID";
    #     };
    #   }
    #   {
    #     condition = "gitdir:~/dev/personal/";
    #     contents = {
    #       user.email = "personal@example.com";
    #       user.signingkey = "PERSONAL_GPG_KEY_ID";
    #     };
    #   }
    # ];
  };

  # === Delta Configuration ===
  # Modern diff viewer with syntax highlighting
  # Docs: https://dandavison.github.io/delta/
  programs.delta = {
    enable = true;
    options = {
      # Navigation: Use 'n' and 'N' to jump between diff sections
      navigate = true;

      # Display options optimized for Ghostty terminal
      side-by-side = true; # Side-by-side view for better readability
      line-numbers = true; # Show line numbers for easier reference

      # Theme: Omit to auto-detect from terminal (Ghostty)
      # Or set explicitly: syntax-theme = "Dracula";

      # Styling
      features = "side-by-side line-numbers decorations";

      # Color customization for added/removed lines
      # Uses Signal theme: darker green for additions, darker red for deletions
      plus-style = "syntax ${theme._internal.accent.Lc45-h130.hex}";
      minus-style = "syntax ${theme._internal.accent.Lc45-h040.hex}";
    };
  };
}
