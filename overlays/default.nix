{
  inputs,
  system,
}: let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
in
  [
    # Local overlays
    (import ./cursor.nix)
    (import ./npm-packages.nix)

    # External overlays from flake inputs
    inputs.yazi.overlays.default
    inputs.niri.overlays.niri
    inputs.nur.overlays.default
    inputs.nh.overlays.default

    # Package-specific overlays
    (import ./waybar.nix {inherit inputs;})
    (import ./swww.nix {inherit inputs;})
  ]
  # Platform-specific overlays
  ++ (
    if isDarwin
    then [
      (import ./ghostty.nix {inherit inputs;})
    ]
    else []
  )
  # Conditional overlays based on available inputs
  ++ (
    if inputs ? nvidia-patch
    then [
      inputs.nvidia-patch.overlays.default
    ]
    else []
  )
