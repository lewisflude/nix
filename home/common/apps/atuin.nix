{
  programs.atuin = {
    enable = true;
    # Zsh integration disabled - using cached init script in cached-init.nix for better performance
    enableZshIntegration = false;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      search_mode = "fuzzy";
    };
  };
}
