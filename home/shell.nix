{ pkgs, config, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      switch = "sudo darwin-rebuild switch --flake ~/.config/nix";
      ls = "lsd";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      cd = "z";
      lt = "ls --tree";
      edit = "sudo -e";
      update = "system-update";
    };
    history = {
      save = 10000;
      size = 10000;
      ignoreAllDups = true;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignorePatterns = [ "rm *" "pkill *" "cp *" ];
    };
    plugins = [
      {
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
    initContent = ''
      source ~/.p10k.zsh
    '';
  };

  # Environment variables managed by home-manager
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };

  # Environment path management
  home.sessionPath = [ "$HOME/.local/bin" "$HOME/.nix-profile/bin" ];
}
