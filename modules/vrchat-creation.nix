# VRChat Creation - Unity Hub + ALCOM for avatar/world development
# Requires: Unity 2022.3.22f1, LinuxVRChatSDKPatch (install via ALCOM)
# Fallback: flatpak install flathub com.unity.UnityHub
_: {
  flake.modules.nixos.vrchatCreation =
    { pkgs, ... }:
    {
      # xdgOpenUsePortal fixes Unity Hub login callback in FHS sandbox
      xdg.portal.xdgOpenUsePortal = true;

      environment.systemPackages = [ pkgs.vrc-get ];
    };

  flake.modules.homeManager.vrchatCreation =
    { lib, pkgs, ... }:
    {
      home.packages = [
        pkgs.vrc-get
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        # Force X11 mode so Unity and its subprocesses connect through
        # xwayland-satellite as pure X11 clients. Fixes popup focus issues
        # (e.g. "Add Component" search bar) caused by xwayland-satellite
        # mapping override-redirect windows as xdg_popup surfaces.
        (pkgs.symlinkJoin {
          name = "unityhub-x11";
          paths = [
            (pkgs.unityhub.override {
              extraPkgs = fhsPkgs: [
                fhsPkgs.harfbuzz
                fhsPkgs.libogg
              ];
            })
          ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/unityhub \
              --unset WAYLAND_DISPLAY \
              --set GDK_BACKEND x11 \
              --set SDL_VIDEODRIVER x11
          '';
        })
      ];
    };

  flake.modules.darwin.vrchatCreation = _: {
    homebrew.casks = [ "unity-hub" ];
  };
}
