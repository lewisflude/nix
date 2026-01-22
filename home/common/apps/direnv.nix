{
  programs.direnv = {
    enable = true;
    # Zsh integration disabled - using cached init script in cached-init.nix for better performance
    enableZshIntegration = false;
    nix-direnv.enable = true;

    # Performance optimizations
    config = {
      global = {
        # Warn if direnv takes longer than 20 seconds
        warn_timeout = "20s";
        # Allow up to 30 seconds for Nix devShell to load
        # First load takes longer, subsequent loads are cached by nix-direnv
        timeout = "30s";
      };
    };
  };
}
