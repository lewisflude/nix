{
  inputs,
  lib,
  system,
  ...
}:
{
  nixpkgs.overlays =
    [
      # Yazi overlay
      inputs.yazi.overlays.default

      # Niri overlay
      inputs.niri-unstable.overlays.niri

      # Waybar overlay
      (_: _: { waybar-git = inputs.waybar.packages.${system}.waybar; })
      # Hyprland-contrib overlay
      (_: _: { grimblast = inputs.hyprland-contrib.packages.${system}.grimblast; })
      # Ghostty overlay
      (_: _: {
        ghostty = inputs.ghostty.packages.${system}.default.override {
          optimize = "ReleaseFast"; # or "Debug", "ReleaseSafe"
          enableX11 = true;
          enableWayland = true;
          # revision = "custom"; # if you want custom revision
        };
      })
      (final: _prev: {
        swww = inputs.swww.packages.${final.system}.swww;
      })
    ]
    ++ lib.optionals (inputs ? nvidia-patch) [
      # Nvidia patch overlay (conditionally added)
      inputs.nvidia-patch.overlays.default
    ];
}
