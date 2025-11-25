{ ... }:
{
  imports = [

    ./nix

    ./integration

    ./keyboard.nix
    ./keyd.nix
    ./monitor-brightness.nix

    ./zfs.nix
    ./disk-performance.nix

    ./sops.nix

    ./documentation.nix

  ];
}
