{
  programs.direnv = {
    enable = true;
    # Zsh integration disabled - using cached init script in cached-init.nix for better performance
    enableZshIntegration = false;
    nix-direnv.enable = true;
  };
}
