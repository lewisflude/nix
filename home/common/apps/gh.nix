{
  pkgs,
  config,
  lib,
  ...
}:
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
        # New productivity aliases
        clean = "poi";
        notifications = "notify";
      };
    };
  };

  # 3. Dedicated Dashboard Module (better than just the extension)
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
}
