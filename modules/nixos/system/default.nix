{ ... }:
{
  imports = [

    ./nix

    ./integration

    ./keyboard.nix
    ./keyd.nix
    ./monitor-brightness.nix

    ./zfs.nix

    ./sops.nix

    ./documentation.nix

  ];
}
