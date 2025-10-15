# Overlay system with selective application
# Overlays are organized by priority and platform
{
  inputs,
  system,
}: let
  isDarwin = system == "aarch64-darwin" || system == "x86_64-darwin";
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";

  # Helper to make conditional overlays
  mkConditional = condition: overlay:
    if condition
    then overlay
    else (_final: _prev: {});
in rec {
  # === Core Overlays (always applied) ===

  # Unstable packages namespace
  unstable = _final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit system;
      inherit (prev) config;
    };
  };

  # === Application Overlays (always applied) ===

  # Custom packages
  cursor = import ./cursor.nix;
  npm-packages = import ./npm-packages.nix;

  # Package fixes
  pamixer = import ./pamixer.nix;

  # Essential tools
  yazi = inputs.yazi.overlays.default;
  nh = inputs.nh.overlays.default;
  nur = inputs.nur.overlays.default;

  # === Platform-Specific Overlays ===

  # Darwin-only
  ghostty = mkConditional isDarwin (import ./ghostty.nix {inherit inputs;});

  # Linux-only
  niri = mkConditional isLinux inputs.niri.overlays.niri;
  waybar = mkConditional isLinux (import ./waybar.nix {inherit inputs;});
  swww = mkConditional isLinux (import ./swww.nix {inherit inputs;});
  nvidia-patch =
    mkConditional (
      isLinux && inputs ? nvidia-patch
    )
    inputs.nvidia-patch.overlays.default;
}
