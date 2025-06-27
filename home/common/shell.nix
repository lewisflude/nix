{
  pkgs,
  config,
  system,
  lib,
  ...
}:
{

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      switch =
        if lib.hasInfix "darwin" system then
          "sudo darwin-rebuild switch --flake ~/.config/nix"
        else
          "sudo nixos-rebuild switch --flake ~/.config/nix#jupiter";
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

      # Development shell shortcuts
      node-shell = "nix develop ~/.config/nix#node -c $SHELL";
      python-shell = "nix develop ~/.config/nix#python -c $SHELL";
      rust-shell = "nix develop ~/.config/nix#rust -c $SHELL";
      go-shell = "nix develop ~/.config/nix#go -c $SHELL";
      web-shell = "nix develop ~/.config/nix#web -c $SHELL";
      solana-shell = "nix develop ~/.config/nix#solana -c $SHELL";
      devops-shell = "nix develop ~/.config/nix#devops -c $SHELL";
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

      # Enable direnv for automatic environment loading
      eval "$(direnv hook zsh)"

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
    EDITOR = "hx";
  };

  # Environment path management
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.nix-profile/bin"
  ];

  home.file = {
    ".p10k.zsh".source = ./lib/p10k.zsh;
  };

  # Add useful scripts from shell/scripts.nix
  home.packages =
    with pkgs;
    [
      (writeShellScriptBin "system-update" ''
        #!/bin/sh
        set -e
        FLAKE_PATH="${config.home.homeDirectory}/.config/nix"
        UPDATE_INPUTS=0
        RUN_GC=0
        BUILD_ONLY=0

        # Detect system type
        if [[ "$OSTYPE" == "darwin"* ]]; then
          SYSTEM_TYPE="darwin"
          HOST_NAME="Lewiss-MacBook-Pro"
          REBUILD_CMD="sudo darwin-rebuild"
        else
          SYSTEM_TYPE="nixos"
          HOST_NAME="jupiter"
          REBUILD_CMD="sudo nixos-rebuild"
        fi

        # Parse arguments
        if [ $# -eq 0 ]; then
          :
        else
          for arg in "$@"; do
            case $arg in
              --full)
                UPDATE_INPUTS=1
                RUN_GC=1
                ;;
              --inputs)
                UPDATE_INPUTS=1
                ;;
              --gc)
                RUN_GC=1
                ;;
              --build-only)
                BUILD_ONLY=1
                ;;
              --help)
                echo "Usage: system-update [options]"
                echo "  --full       Do a complete update (flake update + GC)"
                echo "  --inputs     Update flake inputs"
                echo "  --gc         Run garbage collection"
                echo "  --build-only Just build but don't activate"
                echo "  --help       Show this help"
                exit 0
                ;;
            esac
          done
        fi

        if [ $UPDATE_INPUTS -eq 1 ]; then
          echo "🔄 Updating flake inputs..."
          nix flake update --flake "$FLAKE_PATH"
        fi

        if [ $BUILD_ONLY -eq 1 ]; then
          echo "⚙️ Building system configuration..."
          $REBUILD_CMD build --flake "$FLAKE_PATH"#$HOST_NAME
          if [ "$SYSTEM_TYPE" = "nixos" ]; then
            echo "🏠 Building home-manager configuration..."
            home-manager build --flake "$FLAKE_PATH"#$HOST_NAME
          fi
        else
          echo "⚙️ Building and activating system configuration..."
          $REBUILD_CMD switch --flake "$FLAKE_PATH"#$HOST_NAME
          if [ "$SYSTEM_TYPE" = "nixos" ]; then
            echo "🏠 Updating home-manager configuration..."
            home-manager switch --flake "$FLAKE_PATH"#$HOST_NAME
          fi
        fi

        if [ $RUN_GC -eq 1 ]; then
          echo "🧹 Running garbage collection..."
          nix-collect-garbage -d
        fi

        echo "✨ System update complete!"
      '')
    ]
    ++ lib.optionals (lib.hasInfix "linux" system) [
      # Linux-only gaming mode script
      (writeShellScriptBin "gaming-mode" ''
        #!/usr/bin/env bash
        GAMING_MODE_FILE="/tmp/gaming-mode"

        if [ -f "$GAMING_MODE_FILE" ]; then
          rm "$GAMING_MODE_FILE"
          hyprctl keyword misc:vrr 1
          powerprofilesctl set balanced
          echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
          notify-send "Gaming Mode" "Disabled" -i "󰊵"
        else
          touch "$GAMING_MODE_FILE"
          hyprctl keyword misc:vrr 1
          powerprofilesctl set performance
          echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
          notify-send "Gaming Mode" "Enabled" -i "󰊴"
        fi
      '')
    ];
}
