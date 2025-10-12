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
        {
          on = "<C-n>";
          run = ''shell -- dragon-drop -x -i -T "$1"'';
          desc = "Drag and drop files with dragon";
        }
        {
          on = "<C-f>";
          run = ''shell -- ya emit cd "$(find . -type d | fzf --preview 'ls -la {}')"'';
          desc = "FZF directory navigation";
        }
        {
          on = "<C-z>";
          run = ''shell -- ya emit cd "$(zoxide query -i)"'';
          desc = "Zoxide smart directory jump";
        }
        {
          on = "<C-s>";
          run = ''shell -- ya emit reveal "$(rg --files-with-matches --no-heading . | fzf --preview 'bat --color=always {}')"'';
          desc = "Search file contents with ripgrep + fzf";
        }
        {
          on = "<C-p>";
          run = ''shell -- bat --paging=always "$0"'';
          desc = "Preview file with bat (syntax highlighting)";
        }
      ];
    };
  };
}
