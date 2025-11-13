{ ... }:
{
  imports = [

    ./containers

    ./media-management
    ./containers-supplemental

    ./caddy.nix
    ./dante-proxy.nix
    ./home-assistant.nix
    ./music-assistant.nix
    ./protonvpn-natpmp.nix
    ./samba.nix
    ./ssh.nix
    ./cockpit.nix
  ];
}
