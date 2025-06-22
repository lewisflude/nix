{ pkgs, config, system, lib, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      switch = if lib.hasInfix "darwin" system 
        then "darwin-rebuild switch --flake ~/.config/nix#macbook-pro" 
        else "sudo nixos-rebuild switch --flake ~/.config/nix#desktop";
      ls = "lsd";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      cd = "z";
      lt = "ls --tree";
      edit = "sudo -e";
      update = "system-update";
      backup = "~/.config/nix/backup.sh";
      backup-restore = "ls -la ~/Backups/nix-config";
      
      # Nix store management
      nix-optimize = "sudo /etc/nix-optimization/optimize-store.sh";
      nix-clean = "sudo /etc/nix-optimization/quick-clean.sh";
      nix-analyze = "sudo /etc/nix-optimization/analyze-store.sh";
      nix-size = "du -sh /nix/store";
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
    initContent = ''
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # Load OpenAI API key from secure file
      if [[ -f ~/.config/secrets/openai-key ]]; then
        export OPEN_API_KEY="$(cat ~/.config/secrets/openai-key)"
      fi

      # Ensure GPG agent is running for SSH support
      gpgconf --launch gpg-agent
      
      # Add GitHub SSH key to GPG agent if available
      if [[ -f ~/.ssh/id_ecdsa_sk_github ]]; then
        if ! ssh-add -l | grep -q "$(ssh-keygen -lf ~/.ssh/id_ecdsa_sk_github.pub 2>/dev/null | awk '{print $2}')"; then
          ssh-add ~/.ssh/id_ecdsa_sk_github 2>/dev/null
        fi
      fi

      bindkey '^X' create_completion
      bindkey '^R' history-incremental-search-backward
      bindkey '^P' up-line-or-history
      bindkey '^N' down-line-or-history
      bindkey '^A' beginning-of-line
      bindkey '^E' end-of-line
      bindkey '^K' kill-line
      bindkey '^U' kill-whole-line

      ${
        let
          zsh_codex = pkgs.fetchFromGitHub {
            owner = "tom-doerr";
            repo = "zsh_codex";
            rev = "6ede649f1260abc5ffe91ef050d00549281dc461";
            hash = "sha256-m3m+ErBakBMrBsoiYgI8AdJZwXgcpz4C9hIM5Q+6lO4=";
          };
        in
        ''
          if [[ -f "${zsh_codex}/zsh_codex.plugin.zsh" ]]; then
            source "${zsh_codex}/zsh_codex.plugin.zsh"
          elif [[ -f "${zsh_codex}/zsh_codex.zsh" ]]; then
            source "${zsh_codex}/zsh_codex.zsh"
          fi
        ''
      }
    '';
  };

  # Environment variables managed by home-manager
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    ZSH_CODEX_PYTHON = "${pkgs.python311}/bin/python3.11";
    PYTHON = "${pkgs.python311}/bin/python3.11";
  };

  # Environment path management
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.nix-profile/bin"
  ];

  home.file = {
    ".local/bin/python".source = "${pkgs.python311}/bin/python3.11";
    ".local/bin/python3".source = "${pkgs.python311}/bin/python3.11";
    ".local/bin/pip".source = "${pkgs.python311}/bin/pip3.11";
    ".local/bin/pip3".source = "${pkgs.python311}/bin/pip3.11";
  };
}
