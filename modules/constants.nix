# Application constants as top-level options
# Dendritic pattern: Constants are top-level options, not _module.args
{ lib, ... }:
{
  options.constants = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      # Service ports - centralized to avoid conflicts
      ports = {
        mcp = {
          docs = 6280;
          figma = 3845;
        };

        services = {
          restic = 8000;
          ollama = 11434;
          openWebui = 7000;
          homeAssistant = 8123;
          cockpit = 9090;
          dante = 1080;
          eternalTerminal = 2022;
          mosh = 60000; # Actually uses range 60000-61000

          # Media management services
          jellyfin = 8096;
          seerr = 5055;
          sonarr = 8989;
          radarr = 7878;
          lidarr = 8686;
          listenarr = 5000;
          prowlarr = 9696;
          qbittorrent = 8080;
          transmission = 9091;
          sabnzbd = 8084;
          navidrome = 4533;
          bazarr = 6767;
          readarr = 8787;
          flaresolverr = 8191;
          musicAssistant = 8095;

          # Container supplemental services
          homarr = 7575;
          wizarr = 5690;
          jellystat = 3000;
          termix = 8083;
          doplarr = 3142;
          comfyui = 8188;
          janitorr = 8485;
          profilarr = 6868;
          filebrowser = 8400;
          notifiarr = 5454;
          autopulse = 2875;
          huntarr = 9705;

          syncthing = {
            webUi = 8384;
            sync = 22000;
            discovery = 21027;
          };

          sunshine = {
            http = 47990;
            https = 47989;
            rtsp = 48010;
            control = 47998;
            audio = 47999;
            video = 48000;
          };

          hytaleServer = 5520;

          wyoming = {
            whisper = 10300;
            piper = 10200;
          };
        };

        gaming = {
          steamLinkDiscovery = 27031;
          steamLinkTcp = 27036;
          steamLinkStreaming = 27037;
          steamLinkUdp = [
            27036
            27037
          ];
        };
      };

      timeouts = {
        service = {
          start = "300";
          stop = "90";
          restart = "30";
        };
      };

      baseDomain = "blmt.io";

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
          # Run `syncthing device-id` on Mercury after first build, then fill in.
          syncthingId = "";
          gpgAgent = "/Users/lewisflude/.gnupg/S.gpg-agent";
          gpgAgentExtra = "/Users/lewisflude/.gnupg/S.gpg-agent.extra";
        };
      };

      networks = {
        lan = {
          primary = "192.168.10.0/24";
          secondary = "192.168.0.0/16";
          prefix = "192.168.10.";
          secondaryPrefix = "192.168.0.";
        };
        vpn = {
          cidr = "10.2.0.0/24";
        };
        vpnNamespace = {
          gateway = "192.168.15.1";
        };
        localhost = {
          ipv4 = "127.0.0.1";
          ipv6 = "::1";
          cidr = "127.0.0.1/32";
        };
        all = {
          ipv4 = "0.0.0.0";
          cidr = "0.0.0.0/0";
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
          "https://cache.garnix.io"
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
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        ];
      };
    };
    description = "Application constants (ports, paths, defaults, binary caches)";
  };
}
