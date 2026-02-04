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
          cleanuparr = 11011;

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

        vr = {
          wivrn = {
            tcp = 9757;
            udp = 9757;
          };

          immersed = {
            tcpStart = 5230;
            udpStart = 5230;
          };

          mdns = 5353;
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
        };
        mercury = {
          ipv4 = "192.168.10.220";
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

      audio = {
        devices = {
          usbAudioClass = "~alsa_output.usb-.*";
          apogee = "~alsa_output.usb-Apogee.*";
        };

        virtualSinks = {
          gamingBridge = "apogee_stereo_game_bridge";
          sunshineStereo = "sink-sunshine-stereo";
        };

        priorities = {
          primaryInterface = 100;
          gamingBridge = 100;
          sunshine = 150;
          bluetooth = 80;
          onboard = 50;
          hdmi = 30;
          fallback = 10;
        };
      };

      binaryCaches = {
        substituters = [
          "https://chaotic-nyx.cachix.org"
          "https://nix-community.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
          "https://numtide.cachix.org"
          "https://nixpkgs-python.cachix.org"
          "https://lewisflude.cachix.org"
          "https://niri.cachix.org"
          "https://ghostty.cachix.org"
          "https://yazi.cachix.org"
          "https://ags.cachix.org"
          "https://helix.cachix.org"
          "https://zed.cachix.org"
          "https://cache.garnix.io"
          "https://devenv.cachix.org"
          "https://viperml.cachix.org"
          "https://cuda-maintainers.cachix.org"
          "https://claude-code.cachix.org"
          "https://cache.numtide.com"
        ];

        trustedPublicKeys = [
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
          "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
          "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
          "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };
    };
    description = "Application constants (ports, paths, defaults, binary caches)";
  };
}
