{ ... }:
{
  imports = [
    ./media-management
    ./containers-supplemental

    ./caddy.nix
    ./dante-proxy.nix
    ./eternal-terminal.nix
    ./fail2ban.nix
    ./home-assistant.nix
    ./mosh.nix
    ./music-assistant.nix
    ./samba.nix
    ./ssh.nix
    ./cockpit.nix
  ];
}
