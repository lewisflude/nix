# Application constants as top-level options
# Dendritic pattern: Constants are top-level options, not _module.args
{ lib, ... }:
let
  # Service ports - centralized to avoid conflicts.
  # Hoisted out of `default` so the collision check below can see them.
  ports = {
    mcp = {
      docs = 6280;
    };

    services = {
      restic = 8000;
      openWebui = 7000;
      homeAssistant = 8123;
      eternalTerminal = 2022;
      # Mosh allocates one UDP port per session from this range.
      mosh = {
        from = 60000;
        to = 61000;
      };

      # Media management services
      jellyfin = 8096;
      seerr = 5055;
      sonarr = 8989;
      radarr = 7878;
      lidarr = 8686;
      listenarr = 5000;
      prowlarr = 9696;
      qbittorrent = 8080;
      sabnzbd = 8084;
      bazarr = 6767;
      byparr = 8191; # FlareSolverr drop-in replacement (same port, Camoufox-based)
      musicAssistant = 8095;
      audiobookshelf = 13378;
      calibreWeb = 8093; # Calibre-Web-Automated host port (container listens on 8083)
      cleanuparr = 11011;

      # Container supplemental services
      homarr = 7575;
      wizarr = 5690;
      termix = 8083;
      janitorr = 8485;
      filebrowser = 8400;
      autopulse = 2875;

      # Monero node. Both are loopback/outbound only -- neither is opened in
      # the firewall (see modules/monero.nix).
      monero = {
        rpc = 18081;
        p2p = 18080;
      };

      syncthing = {
        webUi = 8384;
        sync = 22000;
        discovery = 21027;
      };

      # Only `https` is consumed (modules/caddy.nix). The other Sunshine
      # ports are opened by `openFirewall = true` in modules/sunshine.nix
      # rather than from this list, so duplicating them here would be a
      # second source of truth that nothing reads.
      sunshine = {
        https = 47989;
      };

      wyoming = {
        whisper = 10300;
        piper = 10200;
      };
    };

    gaming = {
      steamLinkTcp = 27036;
      steamLinkStreaming = 27037;
      steamLinkUdp = [
        27036
        27037
      ];
    };
  };

  # The comment above promises ports are "centralized to avoid conflicts", but
  # nothing enforced it. `lib.collect` does not descend into lists, so
  # gaming.steamLinkUdp's deliberate repeat of steamLinkTcp/Streaming is not a
  # false positive. No-op on the current tree; trips the moment two services
  # claim the same port.
  allPorts = lib.collect builtins.isInt ports;
  duplicatePorts = lib.unique (lib.filter (p: lib.count (q: q == p) allPorts > 1) allPorts);
in
{
  options.constants = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      lib.throwIf (duplicatePorts != [ ])
        "constants.ports: duplicate port(s) ${lib.concatMapStringsSep ", " toString duplicatePorts}"
        {
          inherit ports;

          baseDomain = "blmt.io";

          gpg = {
            signingKey = "64CA14D5A2396CC0";
            sshAuthKey = "495B10388160753867D2B6F7CAED2ED08F4D4323";
          };

          # SSH public keys authorized for the primary user.
          # Single source of truth: consumed by jupiter (NixOS openssh.authorizedKeys)
          # and mercury (nix-darwin users.users.<name>.openssh.authorizedKeys).
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyBDIzK/OoFY7M1i96wP9wE+OeKk56iTvPwStEiFc+k lewis@lewisflude.com"
            "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBGB2FdscjELsv6fQ4dwLN7ky3Blye+pxJHBfACdYmxhgPodPaRLqbekyrt+XDdXvQYmuiZ0XIa/fL4/452g5MWcAAAAEc3NoOg== lewis@lewisflude.com"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuc2y4LO/GMf02/as8OqUB+zKl+sU44umYXNVC7KzF9 termix@phone"
            # The key the iOS client actually presents today (SHA256:JBMnQX3f...).
            # It previously lived only in jupiter's ~/.ssh/authorized_keys, so
            # phone access was undeclared and mercury rejected it.
            "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL9zRrDvYpeH9zmtzNEMbMaML1mZOilWZbWfHtwDP0cn36PO0lyuRqsKYlrgmCrTdGkh34gk2hQvI4HMeGf2Bxs= ios@phone"
          ];

          defaults = {
            timezone = "Europe/London";
            locale = "en_GB.UTF-8";
            stateVersion = "25.05";
            darwinStateVersion = 6;
          };

          hosts = {
            jupiter = {
              ipv4 = "192.168.10.210";
              tailscaleIpv4 = "100.76.12.92";
              syncthingId = "XYROGRP-W5HF5YD-FGHGC3U-LG4SMQA-CKGFFCP-YWEIG5C-5GVSB4G-HOWRNQZ";
              gpgAgent = "/run/user/1001/gnupg/S.gpg-agent";
              gpgAgentExtra = "/run/user/1001/gnupg/S.gpg-agent.extra";
            };
            mercury = {
              ipv4 = "192.168.10.211";
              tailscaleIpv4 = "100.80.145.75";
              syncthingId = "3DND4DW-PRAXVKZ-67ZMX3X-LEDOZXV-BYHULLC-HZWOIXS-OHMVBM3-REPLDAD";
              gpgAgent = "/Users/lewisflude/.gnupg/S.gpg-agent";
              gpgAgentExtra = "/Users/lewisflude/.gnupg/S.gpg-agent.extra";
            };
            iphone = {
              tailscaleIpv4 = "100.83.166.64";
              syncthingId = "NMKUCPE-KVQV4WW-MLPUWLS-ICPXTOM-IMZA7MV-MED4UDR-GCTZIEZ-BDDBQA2";
            };
          };

          networks = {
            lan = {
              primary = "192.168.10.0/24";
              secondary = "192.168.0.0/16";
            };
            # ProtonVPN WireGuard tunnel used by the confined qBittorrent stack.
            # qbittorrent.nix and protonvpn-portforward.nix both consume these and
            # MUST agree: the port-forward loop re-asserts `interfaceAddress` on the
            # qBittorrent WebUI every time NAT-PMP hands out a new port, so a drift
            # between the two silently binds the torrent listener to the wrong
            # address. The interface inside the namespace is `${namespace}0`.
            vpn = {
              namespace = "qbt";
              interfaceAddress = "10.2.0.2";
              gateway = "10.2.0.1";
            };
            vpnNamespace = {
              gateway = "192.168.15.1";
            };
          };

          binaryCaches = {
            substituters = [
              "https://cache.flakehub.com"
              "https://lewisflude.cachix.org"
              "https://nix-community.cachix.org"
              "https://chaotic-nyx.cachix.org"
              "https://niri.cachix.org"
              "https://cuda-maintainers.cachix.org"
              "https://claude-code.cachix.org"
              "https://devenv.cachix.org"
            ];

            trustedPublicKeys = [
              "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
              "cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio="
              "cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU="
              "cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU="
              "cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8="
              "cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ="
              "cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o="
              "cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="
              "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
              "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
              "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
              "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            ];
          };
        };
    description = "Application constants (ports, paths, defaults, binary caches)";
  };
}
