# Gaming Module
# References:
# - https://wiki.nixos.org/wiki/Steam
# - https://lvra.gitlab.io/docs/distros/nixos/
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    let
      patchedBwrap = pkgs.bubblewrap.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ./bwrap.patch ];
      });
    in
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        extraCompatPackages = [
          pkgs.proton-ge-bin
          pkgs.proton-ge-rtsp-bin
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
            export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
          '';
          extraEnv = {
            PRESSURE_VESSEL_FILESYSTEMS_RW = "$XDG_RUNTIME_DIR/wivrn/comp_ipc";
            PRESSURE_VESSEL_FILESYSTEMS_RO = "/nix/store";
          };
          extraPkgs = pkgs': [
            pkgs'.xorg.libXcursor
            pkgs'.xorg.libXi
            pkgs'.xorg.libXinerama
            pkgs'.xorg.libXScrnSaver
            pkgs'.libpng
            pkgs'.libpulseaudio
            pkgs'.libvorbis
            pkgs'.stdenv.cc.cc.lib
            pkgs'.libkrb5
            pkgs'.keyutils
            pkgs.xrizer # Use outer pkgs (has our overlay)
          ];
        };
      };

      programs.gamemode.enable = true;
    };

  flake.modules.homeManager.gaming =
    {
      pkgs,
      lib,
      osConfig ? { },
      ...
    }:
    let
      gamingEnabled = osConfig.host.features.gaming.enable or false;
    in
    lib.mkIf (gamingEnabled && pkgs.stdenv.isLinux) {
      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
      };

      home.packages = [
        pkgs.steam-run
      ];
    };
}
