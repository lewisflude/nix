# Powerlevel10k ZSH theme configuration
# Uses native home-manager programs.zsh.plugins for cleaner integration
_:
{
  flake.modules.homeManager.powerlevel10k =
    { pkgs, ... }:
    {
      # Install the Meslo font used by Powerlevel10k
      home.packages = [ pkgs.meslo-lgs-nf ];

      # Use native programs.zsh.plugins for cleaner integration
      programs.zsh.plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = ../pkgs;
          file = "p10k.zsh";
        }
      ];
    };
}
