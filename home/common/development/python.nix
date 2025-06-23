{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.virtualenv
    python312Packages.poetry
    python313Packages.uv
  ];
}
