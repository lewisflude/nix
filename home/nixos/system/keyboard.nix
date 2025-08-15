{pkgs, ...}: {
  # Linux keyboard configuration tools
  home.packages = with pkgs; [
    vial
    via
  ];
}
