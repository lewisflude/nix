{
  config,
  lib,
  pkgs,
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
      pkgs.meslo-lgs-nf # Powerlevel10k recommended font
    ];

    # Deploy p10k config from repository
    home.file.".p10k.zsh".source = ./p10k.zsh;

    programs.zsh.initContent = ''
      if [[ -r "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme" ]]; then
        source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      fi

      # Source p10k config
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
  };
}
