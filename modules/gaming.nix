# Gaming Module
# References:
# - https://wiki.nixos.org/wiki/Steam
# - https://lvra.gitlab.io/docs/distros/nixos/
{ config, ... }:
let
  inherit (config) constants;
in
{
  # Java 25 for Hytale (falls back gracefully if missing)
  overlays.java25 =
    _final: prev:
    let
      jdk25 =
        prev.temurin_25_jdk or (prev.jdk25 or (prev.openjdk25 or (builtins.trace ''
          WARNING: Java 25 not found in nixpkgs, falling back to JDK ${prev.jdk.version}
        '' prev.jdk)
        )
        );
    in
    {
      inherit jdk25;
      java25 = jdk25;
    };

  # TECH-DEBT: GCC 15 ICE workarounds for i686-linux (Steam FHS env pulls these in).
  # Each entry below either ICEs at -O2 or has tests that fail under i686 GCC 15.
  # Remove each entry by attempting `nix build .#legacyPackages.i686-linux.<pkg>` after
  # nixpkgs bumps GCC; drop the whole overlay once all entries build cleanly.
  overlays.i686-test-fixes =
    _final: prev:
    if prev.stdenv.hostPlatform.system == "i686-linux" then
      let
        lowerOptLevel =
          pkg:
          pkg.overrideAttrs (old: {
            env = (old.env or { }) // {
              NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -O1";
            };
          });
        skipTests = pkg: pkg.overrideAttrs { doCheck = false; };
        skipAllTests =
          pkg:
          pkg.overrideAttrs {
            doCheck = false;
            doInstallCheck = false;
          };
      in
      {
        onetbb = skipTests prev.onetbb;
        flac = skipTests prev.flac;
        ffmpeg-headless = skipTests prev.ffmpeg-headless;
        libpulseaudio = skipTests prev.libpulseaudio;
        git = lowerOptLevel (skipAllTests prev.git);
        gitMinimal = lowerOptLevel (skipAllTests prev.gitMinimal);
        cargo = lowerOptLevel prev.cargo;
        sane-backends = lowerOptLevel prev.sane-backends;
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_python-final: python-prev: {
            pycairo = python-prev.pycairo.overridePythonAttrs { doCheck = false; };
            filelock = python-prev.filelock.overridePythonAttrs { doCheck = false; };
            distutils = python-prev.distutils.overridePythonAttrs { doCheck = false; };
            hypothesis = python-prev.hypothesis.overridePythonAttrs { doCheck = false; };
          })
        ];
      }
    else
      { };

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
          extraEnv = {
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
          ];
        };
      };

      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };
      programs.steam.gamescopeSession.enable = true;

      boot.kernel.sysctl = {
        "vm.max_map_count" = 2147483642;
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
