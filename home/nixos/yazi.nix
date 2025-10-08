{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    package = pkgs.yazi.override {
      _7zz = pkgs._7zz-rar;
    };

    settings = {
      mgr = {
        show_hidden = true;
      };
      preview = {
        max_width = 1000;
        max_height = 1000;
      };
    };

    keymap = {
      mgr.prepend_keymap = [
        # Drag and drop integration
        {
          on = "<C-n>";
          run = ''shell -- dragon-drop -x -i -T "$1"'';
          desc = "Drag and drop files with dragon";
        }
        # FZF integration for quick file navigation
        {
          on = "<C-f>";
          run = ''shell -- ya emit cd "$(find . -type d | fzf --preview 'ls -la {}')"'';
          desc = "FZF directory navigation";
        }
        # Zoxide integration for smart jumping to frequent directories
        {
          on = "<C-z>";
          run = ''shell -- ya emit cd "$(zoxide query -i)"'';
          desc = "Zoxide smart directory jump";
        }
        # Ripgrep content search
        {
          on = "<C-s>";
          run = ''shell -- ya emit reveal "$(rg --files-with-matches --no-heading . | fzf --preview 'bat --color=always {}')"'';
          desc = "Search file contents with ripgrep + fzf";
        }
        # Better file preview with bat
        {
          on = "<C-p>";
          run = ''shell -- bat --paging=always "$0"'';
          desc = "Preview file with bat (syntax highlighting)";
        }
      ];
    };
  };
}
