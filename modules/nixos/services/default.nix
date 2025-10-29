{...}: {
  imports = [
    # Legacy container services (being phased out)
    ./containers

    # Native NixOS services
    ./media-management
    ./ai-tools
    ./containers-supplemental

    # Other services
    ./home-assistant.nix
    ./music-assistant.nix
    ./samba.nix
    ./ssh.nix
    # ./cockpit.nix # TEMPORARILY DISABLED: cockpit depends on webkitgtk which was removed
  ];
}
