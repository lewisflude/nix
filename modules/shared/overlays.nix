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
      inputs.yazi.overlays.default
      inputs.niri.overlays.niri
      (_: _: {waybar-git = inputs.waybar.packages.${system}.waybar;})
      (import ../../overlays/cursor.nix)
      (import ../../overlays/npm-packages.nix)
      inputs.nur.overlays.default
      inputs.nh.overlays.default
      (final: _prev: {
        inherit (inputs.swww.packages.${final.system}) swww;
      })
    ]
    ++ lib.optionals platformLib.isLinux [
      (_: _: {
        ghostty = inputs.ghostty.packages.${system}.default.override {
          optimize = "ReleaseFast";
          enableX11 = true;
          enableWayland = true;
        };
      })
    ]
    ++ lib.optionals (inputs ? nvidia-patch) [
      inputs.nvidia-patch.overlays.default
    ];
}
