# Git configuration - ALL config classes in ONE file
# Dendritic pattern: One feature = one file spanning all configurations
{ config, ... }:
{
  # ═══════════════════════════════════════════════════════════════════
  # Home-manager Git configuration (works on NixOS AND Darwin)
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.homeManager.git =
    { pkgs, ... }:
    {
      programs.git = {
        enable = true;
        lfs.enable = true;
        signing = {
          key = config.constants.gpg.signingKey;
          signByDefault = true;
        };
        settings = {
          user.name = config.constants.user.name;
          user.email = config.constants.user.email;
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
          alias = {
            co = "checkout";
            st = "status";
            ci = "commit";
            cm = "commit -m";
            ca = "commit -am";
          };
          mergetool.nixfmt.cmd = "${pkgs.nixfmt}/bin/nixfmt --mergetool \"$BASE\" \"$LOCAL\" \"$REMOTE\" \"$MERGED\"";
          mergetool.nixfmt.trustExitCode = true;
        };
      };

      programs.delta = {
        enable = true;
        options = {
          navigate = true;
          features = "side-by-side line-numbers decorations";
        };
      };

      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
        };
      };
    };
}
