# GitHub CLI and GitHub Actions runner configuration
_: {
  flake.modules.nixos.githubRunners =
    { config, pkgs, ... }:
    {
      services.github-runners.tunnels-linux = {
        enable = true;
        url = "https://github.com/beigethreat/tunnels";
        name = "jupiter-tunnels";
        tokenFile = config.sops.secrets.GITHUB_TOKEN.path;
        tokenType = "access";
        replace = true;

        extraLabels = [
          "linux"
          "nixos"
          "x64"
          "tunnels-heavy"
        ];

        extraPackages = with pkgs; [
          awscli2
          bashInteractive
          cmake
          coreutils
          curl
          git
          jq
          just
          nix
          pluginval
        ];
      };
    };

  flake.modules.homeManager.gh =
    { pkgs, ... }:
    {
      programs.gh = {
        enable = true;
        extensions = [
          pkgs.gh-poi # Safely clean up merged branches
          pkgs.gh-notify # View notifications with fzf support
          pkgs.gh-markdown-preview # Terminal markdown rendering
        ];

        settings = {
          editor = "hx";
          git_protocol = "ssh";
          prompt = "enabled";
          aliases = {
            co = "pr checkout";
            pv = "pr view";
            clean = "poi";
            notifications = "notify";
          };
        };
      };

      programs.gh-dash = {
        enable = true;
        settings = {
          prSections = [
            {
              title = "My Pull Requests";
              filters = "is:open author:@me";
            }
            {
              title = "Needs My Review";
              filters = "is:open review-requested:@me";
            }
          ];
        };
      };
    };
}
