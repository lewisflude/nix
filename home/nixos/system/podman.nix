{
  pkgs,
  virtualisation ? { },
  ...
}:
let
  podmanEnabled = virtualisation.podman or virtualisation.enablePodman or false;
in
{
  home.packages =
    if podmanEnabled then
      with pkgs;
      [
        podman
        podman-compose
      ]
    else
      [ ];
}
