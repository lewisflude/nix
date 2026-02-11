# nix-your-shell - Wrapper to retain your shell in nix develop/nix-shell
# Dendritic pattern: Full implementation as flake.modules.homeManager.nixYourShell
_: {
  flake.modules.homeManager.nixYourShell = _: {
    programs.nix-your-shell = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
