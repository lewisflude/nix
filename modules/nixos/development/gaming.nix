{ pkgs, ... }:
let
  steam_run_url = pkgs.writeShellApplication {
    name = "steam-run-url";
    text = ''
      echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
    '';
    runtimeInputs = [
      pkgs.coreutils # For `id` command
    ];
  };
in
{
  environment.systemPackages = with pkgs; [
    lutris
    mangohud
    protonup-qt
    (sunshine.override { cudaSupport = true; })
    moonlight-qt
    steam_run_url
    dwarf-fortress
  ];

  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      package = pkgs.steam.override {
        extraPkgs = pkgs:
          with pkgs; [
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
          ];
      };
    };
  };

  services = {
    sunshine = {
      enable = true;
      package = pkgs.sunshine.override { cudaSupport = true; };
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
    udev = {
      packages = with pkgs; [
        game-devices-udev-rules
      ];
    };
  };

  hardware.uinput.enable = true;
}
