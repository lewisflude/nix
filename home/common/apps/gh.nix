{ pkgs, config, lib, ... }: {
  programs.gh = {
    enable = true;
    extensions = with pkgs; [
      gh-poi               # Safely clean up merged branches
      gh-notify            # View notifications with fzf support
      gh-markdown-preview  # Terminal markdown rendering
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
        { title = "My Pull Requests"; filters = "is:open author:@me"; }
        { title = "Needs My Review"; filters = "is:open review-requested:@me"; }
      ];
    };
  };

  # 4. Copilot CLI & Shell Integration (Replacing the old extension)
  # Note: github-copilot-cli is unfree but allowed at system level
  home.packages = [ pkgs.github-copilot-cli ];
  
  # Add aliases to your shell (assuming zsh/bash)
  home.shellAliases = {
    ghcs = "copilot suggest";
    ghce = "copilot explain";
    # Use 'copilot' for the new 2026 agentic mode
    ask = "copilot"; 
  };
}