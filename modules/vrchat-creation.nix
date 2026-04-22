# VRChat Creation - Unity Hub + ALCOM for avatar/world development
# Requires: Unity 2022.3.22f1, LinuxVRChatSDKPatch (install via ALCOM)
# Fallback: flatpak install flathub com.unity.UnityHub
_: {
  flake.modules.nixos.vrchatCreation = _: {
    # xdgOpenUsePortal fixes Unity Hub login callback in FHS sandbox
    xdg.portal.xdgOpenUsePortal = true;
  };

  flake.modules.homeManager.vrchatCreation =
    { lib, pkgs, ... }:
    let
      unityhub-fhs = pkgs.unityhub.override {
        extraPkgs = fhsPkgs: [
          fhsPkgs.harfbuzz
          fhsPkgs.libogg
        ];
      };

      # Launch Unity inside labwc (nested stacking compositor) so it gets
      # a proper X11 environment via labwc's built-in Xwayland. This avoids
      # xwayland-satellite issues with Unity's override-redirect popups,
      # drag-and-drop crashes, and menu mispositioning on Niri.
      # See: https://github.com/Supreeeme/xwayland-satellite/issues/210
      #
      # Clipboard bridging: a background loop syncs the X11 clipboard inside
      # labwc with the parent Wayland clipboard (Niri) in both directions.
      unity-labwc = pkgs.writeShellScriptBin "unity" ''
        PARENT_WAYLAND_DISPLAY="$WAYLAND_DISPLAY"

        clipboard_bridge() {
          local last_parent="" last_inner=""
          while true; do
            # Parent (Niri) → Inner (labwc X11)
            current_parent=$(WAYLAND_DISPLAY="$PARENT_WAYLAND_DISPLAY" ${lib.getExe' pkgs.wl-clipboard "wl-paste"} -n 2>/dev/null) || true
            if [ -n "$current_parent" ] && [ "$current_parent" != "$last_parent" ] && [ "$current_parent" != "$last_inner" ]; then
              last_parent="$current_parent"
              printf '%s' "$current_parent" | DISPLAY=:0 ${lib.getExe pkgs.xsel} -bi 2>/dev/null || true
            fi

            # Inner (labwc X11) → Parent (Niri)
            current_inner=$(DISPLAY=:0 ${lib.getExe pkgs.xsel} -bo 2>/dev/null) || true
            if [ -n "$current_inner" ] && [ "$current_inner" != "$last_inner" ] && [ "$current_inner" != "$last_parent" ]; then
              last_inner="$current_inner"
              printf '%s' "$current_inner" | WAYLAND_DISPLAY="$PARENT_WAYLAND_DISPLAY" ${lib.getExe' pkgs.wl-clipboard "wl-copy"} 2>/dev/null || true
            fi

            sleep 0.5
          done
        }

        clipboard_bridge &
        CLIP_PID=$!
        trap "kill $CLIP_PID 2>/dev/null" EXIT

        exec ${lib.getExe pkgs.labwc} -s "${lib.getExe' unityhub-fhs "unityhub"}"
      '';
    in
    {
      home.packages = [
        pkgs.vrc-get
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        unityhub-fhs
        unity-labwc
        pkgs.labwc
        pkgs.xsel
      ];
    };

  flake.modules.darwin.vrchatCreation = _: {
    homebrew.casks = [ "unity-hub" ];
  };
}
