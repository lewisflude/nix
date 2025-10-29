{...}: {
  imports = [
    # Nix configuration and optimization
    ./nix

    # System integration (XDG portals, etc.)
    ./integration

    # System maintenance (cleanup, etc.)
    ./maintenance

    # Hardware and device management
    ./keyboard.nix
    ./keyd.nix
    ./monitor-brightness.nix

    # Storage
    ./zfs.nix

    # Secrets management
    ./sops.nix

    # Deprecated/empty modules (to be removed)
    # ./file-management.nix - Empty file
  ];
}
