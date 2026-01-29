# ZSH Runtime Initialization
# Everything that happens at shell startup
{
  config,
  pkgs,
  lib,
  systemConfig,
  sources,
  shellHelpers,
  ...
}:
let
  inherit (shellHelpers) secretAvailable secretPath;
in
{
  # ════════════════════════════════════════════════════════════════
  # Pre-Generated Init Scripts (Build-Time Optimization)
  # ════════════════════════════════════════════════════════════════
  # All init scripts are pre-generated at Nix build time to avoid runtime eval
  # This saves 50-100ms on every shell startup

  home.file.".config/zsh/zoxide-init.zsh".source = pkgs.runCommand "zoxide-init" { } ''
    ${pkgs.zoxide}/bin/zoxide init zsh --cmd cd > $out
  '';

  home.file.".config/zsh/fzf-init.zsh".text = builtins.readFile (
    pkgs.runCommand "fzf-init" { } ''
      ${pkgs.fzf}/bin/fzf --zsh > $out 2>/dev/null || echo "# fzf init" > $out
    ''
  );

  home.file.".config/zsh/direnv-init.zsh".text = builtins.readFile (
    pkgs.runCommand "direnv-init" { } ''
      ${pkgs.direnv}/bin/direnv hook zsh > $out
    ''
  );

  home.file.".config/zsh/atuin-init.zsh".text = builtins.readFile (
    pkgs.runCommand "atuin-init" { } ''
      export HOME="$TMPDIR"
      export ATUIN_CONFIG_DIR="$TMPDIR/.config/atuin"
      mkdir -p "$ATUIN_CONFIG_DIR"
      ${pkgs.atuin}/bin/atuin init zsh --disable-up-arrow > $out 2>&1 || {
        # Fallback: if atuin fails, generate a minimal init script
        echo "# Atuin init (generated fallback)" > $out
        echo "export ATUIN_NOBIND=true" >> $out
      }
    ''
  );

  # ════════════════════════════════════════════════════════════════
  # ZSH Initialization Content
  # ════════════════════════════════════════════════════════════════

  programs.zsh.initContent = lib.mkMerge [
    # ════════════════════════════════════════════════════════════════
    # Early Initialization (lib.mkBefore)
    # ════════════════════════════════════════════════════════════════
    (lib.mkBefore ''
      # Skip ZSH config in Cursor Agent shells for clean command execution
      if [[ "$PAGER" == "head -n 10000 | cat" || "$COMPOSER_NO_INTERACTION" == "1" ]]; then
        return
      fi

      # Suppress direnv output during initialization to avoid p10k instant prompt warnings
      export DIRENV_LOG_FORMAT=""
      export DIRENV_WARN_TIMEOUT=0

      # Note: p10k instant prompt is handled by the powerlevel10k module

      # Load zsh-defer early (required for all deferred loading)
      source ${sources.zsh-defer.src}/zsh-defer.plugin.zsh
    '')

    # ════════════════════════════════════════════════════════════════
    # Main Initialization (lib.mkAfter)
    # ════════════════════════════════════════════════════════════════
    (lib.mkAfter ''
      # ════════════════════════════════════════════════════════════════
      # Cached Initialization (Performance Optimization)
      # ════════════════════════════════════════════════════════════════
      # All init scripts pre-generated at build time - saves 50-100ms

      # Zoxide: Smart directory jumping
      if [[ -f ${config.home.homeDirectory}/.config/zsh/zoxide-init.zsh ]]; then
        source ${config.home.homeDirectory}/.config/zsh/zoxide-init.zsh
      fi

      # FZF: Fuzzy finder
      if [[ -f ${config.home.homeDirectory}/.config/zsh/fzf-init.zsh ]]; then
        source ${config.home.homeDirectory}/.config/zsh/fzf-init.zsh
      fi

      # Direnv: Per-directory environment
      if [[ -f ${config.home.homeDirectory}/.config/zsh/direnv-init.zsh ]]; then
        source ${config.home.homeDirectory}/.config/zsh/direnv-init.zsh
      fi

      # Atuin: Shell history (deferred to avoid blocking prompt)
      if [[ -f ${config.home.homeDirectory}/.config/zsh/atuin-init.zsh ]]; then
        zsh-defer source ${config.home.homeDirectory}/.config/zsh/atuin-init.zsh
      fi

      # ════════════════════════════════════════════════════════════════
      # Dynamic Variables & GPG Configuration
      # ════════════════════════════════════════════════════════════════

      # Optimized GPG_TTY export (faster than $(tty), instant-prompt compatible)
      export GPG_TTY=$TTY

      # GPG agent startup TTY update (deferred for faster startup)
      zsh-defer ${pkgs.gnupg}/bin/gpg-connect-agent --quiet updatestartuptty /bye > /dev/null 2>&1 || true

      # SSH_AUTH_SOCK: Use systemd user service socket (faster, more reliable)
      if [[ -o interactive ]]; then
        # Try systemd socket first (instant lookup, no command substitution)
        if [[ -S "''${XDG_RUNTIME_DIR:-/run/user/$UID}/gnupg/S.gpg-agent.ssh" ]]; then
          export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR:-/run/user/$UID}/gnupg/S.gpg-agent.ssh"
        else
          # Fallback: Cache gpgconf result for session (only run once)
          if [[ -z "$SSH_AUTH_SOCK" ]]; then
            export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"
          fi
        fi
      fi

      # ════════════════════════════════════════════════════════════════
      # Lazy Secret Loading
      # ════════════════════════════════════════════════════════════════
      # Secrets loaded on first command use (not at startup)
      # Improves shell startup time by deferring secret file reads

      ${lib.optionalString (secretAvailable systemConfig "KAGI_API_KEY") ''
        function kagi() {
          if [[ -z "$KAGI_API_KEY" ]]; then
            local secret_path="${lib.escapeShellArg (secretPath systemConfig "KAGI_API_KEY")}"
            [[ -r "$secret_path" ]] && export KAGI_API_KEY="$(cat "$secret_path")"
          fi
          command kagi "$@"
        }
      ''}

      ${lib.optionalString (secretAvailable systemConfig "GITHUB_TOKEN") ''
        function gh() {
          if [[ -z "$GITHUB_TOKEN" ]]; then
            local secret_path="${lib.escapeShellArg (secretPath systemConfig "GITHUB_TOKEN")}"
            [[ -r "$secret_path" ]] && export GITHUB_TOKEN="$(cat "$secret_path")"
          fi
          command gh "$@"
        }
      ''}

      # ════════════════════════════════════════════════════════════════
      # Zstyle Configuration (Completion Styling)
      # ════════════════════════════════════════════════════════════════

      zstyle ':completion:*' completer _complete _match _approximate
      zstyle ':completion:*:match:*' original only
      zstyle ':completion:*:approximate:*' max-errors 1 numeric
      zstyle ':completion:*' matcher-list \
        'm:{a-zA-Z}={A-Za-z}' \
        'r:|[._-]=* r:|=*' \
        'l:|=* r:|=*'
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*' list-colors '${"\${(s.:.)LS_COLORS}"}'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' verbose true
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
      zstyle ':completion:*:corrections' format '%F{green}%d (errors: %e)%f'
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:cd:*' ignore-parents parent pwd
      zstyle ':completion:*' file-patterns '%p:globbed-files *(-/):directories' '*:all-files'

      # ════════════════════════════════════════════════════════════════
      # Shell Options & Correction
      # ════════════════════════════════════════════════════════════════

      unsetopt FLOW_CONTROL

      # Disable correction in non-interactive, non-TTY, or IDE terminals
      if [[ ! -o interactive || ! -t 1 || "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "cursor" ]]; then
        unsetopt CORRECT CORRECT_ALL
      else
        setopt CORRECT
        unsetopt CORRECT_ALL
      fi

      # ════════════════════════════════════════════════════════════════
      # Custom Functions (Load Immediately)
      # ════════════════════════════════════════════════════════════════

      if [[ -f "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/functions.zsh" ]]; then
        source "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/functions.zsh"
      fi

      # Powerlevel10k diagnostic functions
      if [[ -f "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/p10k-diagnostics.zsh" ]]; then
        source "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/p10k-diagnostics.zsh"
      fi

      # ════════════════════════════════════════════════════════════════
      # Deferred Plugin Loading (Non-Blocking)
      # ════════════════════════════════════════════════════════════════
      # Plugins deferred to unblock prompt rendering
      # Configuration variables set in zsh.nix

      # Autosuggestions
      zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      # Auto Notify
      zsh-defer source ${sources.zsh-auto-notify.src}/auto-notify.plugin.zsh

      # History Substring Search
      zsh-defer source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      # ════════════════════════════════════════════════════════════════
      # Syntax Highlighting - MUST BE LAST (Deferred)
      # ════════════════════════════════════════════════════════════════
      # Loads after all other plugins that define commands/aliases
      # Ensures new commands are highlighted correctly

      # Declare ZSH_HIGHLIGHT_STYLES array before signal-nix sets styles
      typeset -gA ZSH_HIGHLIGHT_STYLES

      zsh-defer source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    '')
  ];
}
