{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;

    # Performance optimizations
    # These settings help prevent direnv from blocking the shell
    config = {
      global = {
        # Warn if direnv takes longer than 20 seconds
        warn_timeout = "20s";
        # Fail fast if direnv hangs (prevents infinite blocking)
        timeout = "5s";
      };
    };
  };
}
