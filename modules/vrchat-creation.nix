# VRChat Creation - Unity Hub + ALCOM for avatar/world development
# Requires: Unity 2022.3.22f1, LinuxVRChatSDKPatch (install via ALCOM)
# Fallback: flatpak install flathub com.unity.UnityHub
_: {
  flake.modules.nixos.vrchatCreation =
    { pkgs, ... }:
    {
      environment.systemPackages =
        let
          unityhub-x11 = pkgs.symlinkJoin {
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
                --set GDK_BACKEND x11 \
                --set SDL_VIDEODRIVER x11
            '';
          };
        in
        [
          pkgs.vrc-get
          unityhub-x11
        ];
    };

  flake.modules.homeManager.vrchatCreation =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.vrc-get ];
    };

  flake.modules.darwin.vrchatCreation = _: {
    homebrew.casks = [ "unity-hub" ];
  };
}
