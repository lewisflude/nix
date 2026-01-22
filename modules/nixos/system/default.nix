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
    ./cpu-performance.nix
    ./io-priority.nix
    ./gaming-latency.nix
    ./pci-latency.nix
    ./scheduler.nix

    ./sops.nix

    ./documentation.nix

    ./service-monitoring.nix
    ./boot-analysis.nix

  ];
}
