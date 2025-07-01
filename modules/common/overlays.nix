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

      # Waybar overlay
      (_: _: { waybar_git = inputs.waybar.packages.${system}.waybar; })

    ]
    ++ lib.optionals (inputs ? nvidia-patch) [
      # Nvidia patch overlay (conditionally added)
      inputs.nvidia-patch.overlays.default
    ];
}
