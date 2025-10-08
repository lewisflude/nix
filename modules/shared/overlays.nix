{
  inputs,
  lib,
  system,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
in {
  nixpkgs.overlays =
    [
      # Yazi overlay
      inputs.yazi.overlays.default

      # Niri overlay
      inputs.niri.overlays.niri

      # Waybar overlay
      (_: _: {waybar-git = inputs.waybar.packages.${system}.waybar;})

      # Cursor overlay
      (import ../../overlays/cursor.nix)

      # Custom npm packages overlay
      (import ../../overlays/npm-packages.nix)

      # NUR overlay
      inputs.nur.overlays.default

      # NH overlay
      inputs.nh.overlays.default

      (final: _prev: {
        inherit (inputs.swww.packages.${final.system}) swww;
      })
    ]
    ++ lib.optionals platformLib.isLinux [
      # Ghostty overlay (linux only)
      (_: _: {
        ghostty = inputs.ghostty.packages.${system}.default.override {
          optimize = "ReleaseFast"; # or "Debug", "ReleaseSafe"
          enableX11 = true;
          enableWayland = true;
          # revision = "custom"; # if you want custom revision
        };
      })
    ]
    ++ lib.optionals (inputs ? nvidia-patch) [
      # Nvidia patch overlay (conditionally added)
      inputs.nvidia-patch.overlays.default
    ];
}
