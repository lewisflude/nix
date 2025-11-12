{ ... }:
{
  imports = [

    ./containers

    ./media-management
    ./ai-tools
    ./containers-supplemental

    ./home-assistant.nix
    ./music-assistant.nix
    ./protonvpn-natpmp.nix
    ./samba.nix
    ./ssh.nix
    ./cockpit.nix
  ];
}
