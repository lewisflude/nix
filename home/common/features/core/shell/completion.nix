# ZSH Completion System Configuration
# Completion initialization and styling
{
  config,
  pkgs,
  ...
}:
{
  programs.zsh.completionInit = ''
    # Initialize completion system with aggressive caching
    autoload -Uz compinit

    # Ensure cache directory exists
    mkdir -p ${config.xdg.cacheHome}/zsh

    # Add zsh-completions to fpath before compinit
    fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)

    # Cache compinit dump - aggressively skip compaudit for faster startup
    # This dramatically speeds up shell startup (saves ~26ms from compaudit)
    local zcompdump="${config.xdg.cacheHome}/zsh/.zcompdump"

    # Use simpler, more reliable cache check
    # Only regenerate if dump doesn't exist or is older than 24 hours
    # Always use -C flag (skip compaudit) when dump is fresh
    if [[ ! -f "$zcompdump" ]] || [[ -n "$(find "$zcompdump" -mtime +1 2>/dev/null)" ]]; then
      # Dump doesn't exist or is old (>24hrs), regenerate with full checks
      compinit -d "$zcompdump"
    else
      # Dump is fresh, skip expensive compaudit security check
      compinit -C -d "$zcompdump"
    fi

    # Enable completion caching for expensive completions (e.g., package managers)
    zstyle ':completion:*' use-cache yes
    zstyle ':completion:*' cache-path ${config.xdg.cacheHome}/zsh
  '';
}
