# ZSH Init Content Configuration
# Initialization script sections: environment, plugins, keybindings, prompt
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
  inherit (shellHelpers) secretExportSnippet;
in
{
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkBefore ''

      # Skip the rest of the zsh config inside Cursor Agent shells so commands finish cleanly
      if [[ "$PAGER" == "head -n 10000 | cat" || "$COMPOSER_NO_INTERACTION" == "1" ]]; then
        return
      fi

      # Suppress direnv output during initialization to avoid p10k instant prompt warnings
      export DIRENV_LOG_FORMAT=""
      export DIRENV_WARN_TIMEOUT=0

      # Only load p10k instant prompt in interactive shells
      if [[ -o interactive && -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '')

    (lib.mkAfter ''
      # ════════════════════════════════════════════════════════════════
      # SECTION 1: Environment Variables & Exports
      # ════════════════════════════════════════════════════════════════
      ${secretExportSnippet systemConfig "KAGI_API_KEY" "KAGI_API_KEY"}
      ${secretExportSnippet systemConfig "GITHUB_TOKEN" "GITHUB_TOKEN"}
      export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"
      export SOPS_GPG_EXEC="${lib.getExe pkgs.gnupg}"
      export SOPS_GPG_ARGS="--pinentry-mode=loopback"
      export NIX_FLAKE="${config.home.homeDirectory}/.config/nix"
      export WORDCHARS='*?_-.[]~=&;!'
      export ATUIN_NOBIND="true"

      # ════════════════════════════════════════════════════════════════
      # SECTION 2: Zstyle Configuration (Completion System Styling)
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
      # SECTION 3: Shell Options & Correction
      # ════════════════════════════════════════════════════════════════
      unsetopt FLOW_CONTROL
      if [[ ! -o interactive || ! -t 1 || "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "cursor" ]]; then
        unsetopt CORRECT CORRECT_ALL
      else
        setopt CORRECT
        unsetopt CORRECT_ALL
      fi

      # ════════════════════════════════════════════════════════════════
      # SECTION 4: Custom Functions (Load Immediately)
      # ════════════════════════════════════════════════════════════════
      if [[ -f "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/functions.zsh" ]]; then
        source "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/functions.zsh"
      fi

      # ════════════════════════════════════════════════════════════════
      # SECTION 5: Deferred Plugin Loading (Non-blocking)
      # ════════════════════════════════════════════════════════════════
      # These plugins are deferred to unblock prompt rendering

      # Autosuggestions (with configuration)
      typeset -ga ZSH_AUTOSUGGEST_STRATEGY
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=240"
      zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      # Autopair
      zsh-defer source ${sources.zsh-autopair.src}/autopair.zsh

      # You Should Use (with configuration)
      zsh-defer -c 'export YSU_MESSAGE_POSITION="after"'
      zsh-defer -c 'export YSU_HARDCORE=1'
      zsh-defer source ${sources.zsh-you-should-use.src}/you-should-use.plugin.zsh

      # Auto Notify (with configuration)
      zsh-defer -c 'export AUTO_NOTIFY_THRESHOLD=10'
      zsh-defer -c 'export AUTO_NOTIFY_TITLE="Command finished"'
      zsh-defer -c 'export AUTO_NOTIFY_BODY="Completed in %elapsed seconds"'
      zsh-defer -c 'export AUTO_NOTIFY_IGNORE=(
        "man" "less" "more" "vim" "nano" "htop" "top" "ssh" "scp" "rsync"
        "watch" "tail" "sleep" "ping" "curl" "wget" "git log" "git diff"
      )'
      zsh-defer source ${sources.zsh-auto-notify.src}/auto-notify.plugin.zsh

      # BD (quick directory navigation)
      zsh-defer source ${sources.zsh-bd.src}/bd.zsh

      # History Substring Search (deferred)
      zsh-defer source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      # Codex (AI completion - deferred)
      zsh-defer source ${sources.zsh_codex.src}/zsh_codex.plugin.zsh

      # ════════════════════════════════════════════════════════════════
      # SECTION 6: Keybindings (Interactive Shells Only)
      # ════════════════════════════════════════════════════════════════
      if [[ -o interactive ]]; then
        # CRITICAL: Keybinding conflict resolution
        # Priority: Atuin > FZF (Atuin overwrites Ctrl+R)
        # FZF keeps Ctrl+T (file search) and Alt+C (directory search)
        zsh-defer -c 'bindkey "^r" _atuin_search_widget'

        # History Substring Search (Ctrl+P/N instead of Up/Down to avoid Atuin conflict)
        zsh-defer -c 'bindkey "^P" history-substring-search-up'
        zsh-defer -c 'bindkey "^N" history-substring-search-down'

        # Word navigation (Ctrl+Arrow)
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^H' backward-kill-word
        bindkey '^[[3;5~' kill-word

        # Codex AI completion (Ctrl+X)
        zsh-defer -c 'bindkey "^X" create_completion'

        # Ghostty multiline input support
        function _ghostty_insert_newline() { LBUFFER+=$'\n' }
        zle -N ghostty-insert-newline _ghostty_insert_newline
        bindkey -M emacs $'\e[99997u' ghostty-insert-newline
        bindkey -M viins $'\e[99997u' ghostty-insert-newline
        bindkey -M emacs $'\e\r'     ghostty-insert-newline
        bindkey -M viins $'\e\r'     ghostty-insert-newline
      fi

      # ════════════════════════════════════════════════════════════════
      # SECTION 7: Powerlevel10k (Prompt) - Load After Plugins
      # ════════════════════════════════════════════════════════════════
      if [[ -o interactive ]]; then
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        if [[ -f ${config.home.homeDirectory}/.p10k.zsh ]]; then
          source ${config.home.homeDirectory}/.p10k.zsh
        else
          echo "Warning: ~/.p10k.zsh not found. Run 'home-manager switch' to create it."
        fi
      fi

      # ════════════════════════════════════════════════════════════════
      # SECTION 8: Zoxide (Navigation) - Before Syntax Highlighting
      # ════════════════════════════════════════════════════════════════
      # Use --cmd cd to completely replace the cd command (better than aliasing)
      eval "$(zoxide init zsh --cmd cd)"

      # ════════════════════════════════════════════════════════════════
      # SECTION 9: Syntax Highlighting - MUST BE LAST
      # ════════════════════════════════════════════════════════════════
      # This MUST load after all other plugins that define commands/aliases
      # Otherwise it cannot highlight the new commands correctly
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    '')
  ];
}
