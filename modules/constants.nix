# Application constants as top-level options
# Dendritic pattern: Constants are top-level options, not _module.args
{ lib, ... }:
{
  options.constants = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      # Service ports - centralized to avoid conflicts
      # Port range: 6200-6299 reserved for MCP servers
      ports = {
        mcp = {
          github = 6230;
          git = 6233;
          kagi = 6240;
          openai = 6250;
          docs = 6280;
          rustdocs = 6270;
          fetch = 6260;
          nixos = 6265;
          time-nixos = 6262;
          time-darwin = 6263;
          sequential-thinking-nixos = 6281;
          sequential-thinking-darwin = 6282;
          filesystem = 6220;
          memory = 6221;
          everything = 6222;
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
          jellyseerr = 5055;
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
          autobrr = 7474;
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

          syncthing = {
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
        };

        gaming = {
          steamLinkDiscovery = 27031;
          steamLinkTcp = 27036;
          steamLinkUdp = [
            27036
            27037
          ];
        };
      };

      timeouts = {
        mcp = {
          registration = "60000";
          warmup = "900";
          default = "60000";
        };
        service = {
          start = "300";
          stop = "90";
          restart = "30";
        };
      };

      defaults = {
        timezone = "Europe/London";
        locale = "en_GB.UTF-8";
        stateVersion = "25.05";
        darwinStateVersion = 6;
      };

      hosts = {
        jupiter = {
          ipv4 = "192.168.10.210";
          gpgAgent = "/run/user/1001/gnupg/S.gpg-agent";
          gpgAgentExtra = "/run/user/1001/gnupg/S.gpg-agent.extra";
        };
        mercury = {
          ipv4 = "192.168.10.220";
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
          "https://lewisflude.cachix.org"
          "https://nix-community.cachix.org"
          "https://chaotic-nyx.cachix.org"
          "https://niri.cachix.org"
          "https://cuda-maintainers.cachix.org"
        ];

        trustedPublicKeys = [
          "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        ];
      };
    };
    description = "Application constants (ports, paths, defaults, binary caches)";
  };
}
