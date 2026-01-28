{ ... }:
{
  imports = [
    ./nix
    ./integration/xdg.nix
    ./keyboard.nix
    ./keyd.nix
    ./monitor-brightness.nix
    ./zfs.nix
    ./sops.nix
    ./service-monitoring.nix
    ./boot-analysis.nix
  ];
}
