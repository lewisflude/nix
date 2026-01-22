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
  inherit (shellHelpers) secretAvailable secretPath;
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

      # Note: p10k instant prompt is now handled by the powerlevel10k module

      # ════════════════════════════════════════════════════════════════
      # zsh-defer must load early (before any lib.mkAfter sections)
      # ════════════════════════════════════════════════════════════════
      # This ensures zsh-defer is available when cached-init.nix uses it
      source ${sources.zsh-defer.src}/zsh-defer.plugin.zsh
    '')

    (lib.mkAfter ''
      # ════════════════════════════════════════════════════════════════
      # SECTION 1: Dynamic Variables & Lazy Secret Loading
      # ════════════════════════════════════════════════════════════════
      # Secrets are loaded lazily when commands are first used (not at startup)
      # This improves shell startup time by deferring secret file reads

      # Optimized GPG_TTY export (faster than $(tty), instant-prompt compatible)
      export GPG_TTY=$TTY

      # Lazy-load secrets when commands are first used
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

      # Powerlevel10k diagnostic functions
      if [[ -f "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/p10k-diagnostics.zsh" ]]; then
        source "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/p10k-diagnostics.zsh"
      fi

      # ════════════════════════════════════════════════════════════════
      # SECTION 5: Deferred Plugin Loading (Non-blocking)
      # ════════════════════════════════════════════════════════════════
      # Plugins are deferred to unblock prompt rendering
      # Configuration variables are set in zsh-config.nix (localVariables and initContent)
      # Note: zsh-defer is sourced in lib.mkBefore section above

      # Autosuggestions (configuration set in zsh-config.nix)
      zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      # Auto Notify (configuration in localVariables)
      zsh-defer source ${sources.zsh-auto-notify.src}/auto-notify.plugin.zsh

      # History Substring Search (deferred)
      zsh-defer source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      # Removed plugins for performance:
      # - zsh-autopair: Auto-closing brackets (removed - not essential)
      # - zsh-you-should-use: Hardcore mode wraps 'command' builtin (~14ms command lag)
      # - zsh-bd: Quick directory navigation (removed - use zoxide instead)
      # - zsh-codex: AI completion (removed - not actively used)

      # ════════════════════════════════════════════════════════════════
      # SECTION 6: Keybindings
      # ════════════════════════════════════════════════════════════════
      # Note: Keybindings are now in dedicated keybindings.nix module
      # This includes terminfo-based bindings and application mode hooks

      # ════════════════════════════════════════════════════════════════
      # SECTION 7: Syntax Highlighting - MUST BE LAST (but deferred)
      # ════════════════════════════════════════════════════════════════
      # This MUST load after all other plugins that define commands/aliases
      # Otherwise it cannot highlight the new commands correctly
      # Deferred to unblock prompt rendering (~2.85ms savings)
      # zsh-defer ensures it loads last among deferred plugins

      # Declare ZSH_HIGHLIGHT_STYLES associative array before signal-nix sets styles
      # This prevents "assignment to invalid subscript range" errors
      typeset -gA ZSH_HIGHLIGHT_STYLES

      zsh-defer source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    '')
  ];
}
