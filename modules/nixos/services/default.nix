{ ... }:
{
  imports = [

    ./containers

    ./media-management
    ./ai-tools
    ./containers-supplemental

    ./home-assistant.nix
    ./music-assistant.nix
    ./samba.nix
    ./ssh.nix
    ./cockpit.nix
    ./protonvpn-port-forwarding.nix
    ./wireguard-qbittorrent.nix
  ];
}
