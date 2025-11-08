{ lib, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      italic-text = "always";
      theme = lib.mkDefault "base16"; # Neutral theme, can be overridden
      style = "numbers,changes,header";
      paging = "never";
      color = "always";
    };
  };
}
