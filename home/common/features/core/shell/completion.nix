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

    # Cache compinit dump - only regenerate once per day
    # This dramatically speeds up shell startup
    local zcompdump="${config.xdg.cacheHome}/zsh/.zcompdump"

    # Check if dump file is older than 24 hours
    if [[ -f "$zcompdump" && -n "$zcompdump"(#qN.mh+24) ]]; then
      # Dump is old, regenerate with full checks
      compinit -d "$zcompdump"
    elif [[ -f "$zcompdump" ]]; then
      # Dump is fresh, use cached version (skip expensive checks)
      compinit -C -d "$zcompdump"
    else
      # No dump exists, create it
      compinit -i -d "$zcompdump"
    fi

    # Enable completion caching for expensive completions (e.g., package managers)
    zstyle ':completion:*' use-cache yes
    zstyle ':completion:*' cache-path ${config.xdg.cacheHome}/zsh
  '';
}
