{pkgs, ...}: {
  home.packages = with pkgs; [
    vial
    via
  ];
}
