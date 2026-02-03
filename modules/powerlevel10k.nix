# Powerlevel10k ZSH theme configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.powerlevel10k
{ config, ... }:
{
  flake.modules.homeManager.powerlevel10k =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.powerlevel10k;
    in
    {
      options.programs.powerlevel10k = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Powerlevel10k ZSH theme";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          pkgs.zsh-powerlevel10k
          pkgs.meslo-lgs-nf
        ];

        # Deploy p10k config from packages directory
        home.file.".p10k.zsh".source = ../packages/p10k.zsh;

        programs.zsh.initContent = ''
          if [[ -r "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme" ]]; then
            source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
          fi
          [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
        '';
      };
    };
}
