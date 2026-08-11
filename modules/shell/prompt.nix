# Powerlevel10k prompt.
#
# Contributes to flake.modules.homeManager.shell rather than standing alone —
# the instant-prompt bootstrap has to be interleaved into the .zshrc ordering
# contract documented in zsh.nix, so it cannot be composed independently.
#
# Note: upstream powerlevel10k is in maintenance only. Migrating to starship is
# the eventual path; nothing here blocks that beyond swapping this one file.
_: {
  flake.modules.homeManager.shell =
    hmArgs@{ lib, pkgs, ... }:
    let
      hmConfig = hmArgs.config;
    in
    {
      programs.zsh.plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          # A directory holding only p10k.zsh. It previously pointed at the
          # repo's whole pkgs/ tree, which copied every unrelated package into
          # the store and put it all on $PATH and $fpath.
          name = "powerlevel10k-config";
          src = ./p10k;
          file = "p10k.zsh";
        }
      ];

      # Order 150: after the agent-shell guard, before everything that could
      # write to the console. p10k.zsh was generated with instant_prompt=verbose
      # but nothing ever sourced the cache, so the feature was inert.
      programs.zsh.initContent = lib.mkOrder 150 ''
        if [[ -r "${hmConfig.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "${hmConfig.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '';
    };
}
