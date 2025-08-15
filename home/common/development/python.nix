{pkgs, ...}: {
  home.packages = with pkgs; [
    python313
    python313Packages.pip
    python313Packages.uv
  ];
}
