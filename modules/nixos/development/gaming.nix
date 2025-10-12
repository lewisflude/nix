{pkgs, ...}: {
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
      package = pkgs.sunshine.override {cudaSupport = true;};
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
