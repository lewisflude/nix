{ lib, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      italic-text = "always";
      theme = lib.mkDefault "Catppuccin Mocha";
      style = "numbers,changes,header";
      paging = "never";
      color = "always";
    };
  };
}
