# Gaming Module
# References:
# - https://wiki.nixos.org/wiki/Steam
# - https://lvra.gitlab.io/docs/distros/nixos/
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.gaming =
    {
      pkgs,
      lib,
      ...
    }:
    let
      patchedBwrap = pkgs.bubblewrap.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../patches/bwrap.patch ];
      });
    in
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = [
          pkgs.proton-ge-bin
        ];
        package = pkgs.steam.override {
          buildFHSEnv =
            args:
            (
              (pkgs.buildFHSEnv.override {
                bubblewrap = patchedBwrap;
              })
              (
                args
                // {
                  extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [ "--cap-add ALL" ];
                }
              )
            );
          extraProfile = ''
            unset TZ
          '';
          # VR integration: These must be part of the Steam package override (not vr.nix)
          # because programs.steam.package is a single atomic override.
          # See modules/vr.nix for the rest of VR configuration.
          extraEnv = {
            PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = "1";
            PRESSURE_VESSEL_FILESYSTEMS_RW = "$XDG_RUNTIME_DIR/wivrn/comp_ipc";
            PRESSURE_VESSEL_FILESYSTEMS_RO = "/nix/store";
          };
          extraPkgs = pkgs': [
            pkgs'.libxcursor
            pkgs'.libxi
            pkgs'.libxinerama
            pkgs'.libxscrnsaver
            pkgs'.libpng
            pkgs'.libpulseaudio
            pkgs'.libvorbis
            pkgs'.stdenv.cc.cc.lib
            pkgs'.libkrb5
            pkgs'.keyutils
            pkgs.xrizer # VR: OpenVR compatibility layer (outer pkgs, has multilib overlay)
          ];
        };
      };

      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };
      programs.steam.gamescopeSession.enable = true;

      boot.kernel.sysctl = {
        "vm.swappiness" = lib.mkDefault 10;
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
      };

      programs.gamemode = {
        enable = true;
        settings = {
          general = {
            renice = -10;
          };
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
          };
          cpu = {
            park_cores = "no";
            pin_cores = "yes";
          };
        };
      };

      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
      };

      # Steam Link streaming ports
      networking.firewall = {
        allowedTCPPorts = [
          constants.ports.gaming.steamLinkTcp
          constants.ports.gaming.steamLinkStreaming
        ];
        allowedUDPPorts = constants.ports.gaming.steamLinkUdp;
      };
    };

  flake.modules.darwin.gaming = _: {
    homebrew.casks = [
      "epic-games"
      "moonlight"
      "obs@beta"
      "steam"
    ];
  };

  flake.modules.homeManager.gaming =
    {
      pkgs,
      lib,
      ...
    }:
    lib.mkIf pkgs.stdenv.isLinux {
      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
      };

      home.packages = [
        pkgs.protonup-qt
        pkgs.moonlight-qt
      ];
    };

}
