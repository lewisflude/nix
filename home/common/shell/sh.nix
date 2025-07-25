{
  pkgs,
  config,
  ...
}:
{

  home.file = {
    ".p10k.zsh" = {
      source = ../lib/p10k.zsh;
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    loginExtra = ''[[ -f /etc/zprofile ]] && source /etc/zprofile'';
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      eval "$(zoxide init zsh)"
      eval "$(direnv hook zsh)"
      source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
      source "${pkgs.fzf}/share/fzf/completion.zsh"
      export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    '';

    shellAliases = {
      ls = "eza";
      l = "eza -l";
      la = "eza -la";
      lla = "eza -la";
      cd = "z";
      lt = "eza --tree";
      edit = "sudo -e";
      update = "system-update";
    };
    history = {
      save = 10000;
      size = 10000;
      ignoreAllDups = true;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignorePatterns = [
        "rm *"
        "pkill *"
        "cp *"
      ];
    };

    plugins = [
      {
        # will source zsh-autosuggestions.plugin.zsh
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.1";
          sha256 = "sha256-vpTyYq9ZgfgdDsWzjxVAE7FZH4MALMNZIFyEOBLm5Qo=";
        };
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  };
}
