# Direnv - Per-directory environment variables
_: {
  flake.modules.homeManager.direnv = _: {
    programs.direnv = {
      enable = true;
      # Zsh integration disabled - using cached init script in modules/shell.nix for better performance
      enableZshIntegration = false;
      nix-direnv.enable = true;
    };
  };
}
