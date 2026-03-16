# VRChat Creation - Unity Hub + ALCOM for avatar/world development
# Requires: Unity 2022.3.22f1, LinuxVRChatSDKPatch (install via ALCOM)
# Fallback: flatpak install flathub com.unity.UnityHub
_: {
  flake.modules.nixos.vrchatCreation =
    { pkgs, ... }:
    {
      # xdgOpenUsePortal fixes Unity Hub login callback in FHS sandbox
      xdg.portal.xdgOpenUsePortal = true;

      environment.systemPackages = [
        pkgs.vrc-get
        (pkgs.unityhub.override {
          extraPkgs = fhsPkgs: [
            fhsPkgs.harfbuzz
            fhsPkgs.libogg
          ];
        })
      ];
    };
}
