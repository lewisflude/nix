{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python313
    python313Packages.openai
    python313Packages.pip
  ];
}
