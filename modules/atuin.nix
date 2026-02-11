# Atuin - Shell history sync and search
_: {
  flake.modules.homeManager.atuin = _: {
    programs.atuin = {
      enable = true;
      # Zsh integration disabled - using cached init script in modules/shell.nix for better performance
      enableZshIntegration = false;
      flags = [ "--disable-up-arrow" ];
      settings = {
        sync_frequency = "5m";
      };
    };
  };
}
