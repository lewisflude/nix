{
  inputs,
  lib,
  ...
}:
{
  nixpkgs.overlays =
    [
      # Yazi overlay
      inputs.yazi.overlays.default

      # Waybar overlay
      (final: _: { waybar_git = inputs.waybar.packages.${final.system}.waybar; })

      # Ghostty overlay
      (final: prev: {
        ghostty = inputs.ghostty.packages.${final.system}.default;
      })
    ]
    ++ lib.optionals (inputs ? nvidia-patch) [
      # Nvidia patch overlay (conditionally added)
      inputs.nvidia-patch.overlays.default
    ];
}
