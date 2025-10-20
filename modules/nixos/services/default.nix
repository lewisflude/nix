{...}: {
  imports = [
    ./containers
    ./home-assistant.nix
    ./music-assistant.nix
    ./samba.nix
    ./ssh.nix
    ./cockpit.nix
  ];
}
