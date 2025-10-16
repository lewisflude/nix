# Overlay system with selective application
# Overlays are organized by priority and platform
{
  inputs,
  system,
}: let
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
    unstable = import inputs.nixpkgs {
      inherit system;
      inherit (prev) config;
    };
  };

  # === Application Overlays (always applied) ===

  # Auto-import all packages from ../pkgs (each subdirectory with a default.nix)
  localPkgs = _final: prev: let
    pkgsDir = ../pkgs;
    # Read all entries in the pkgs directory
    dirEntries = builtins.readDir pkgsDir;
    # Filter for entries that are directories AND have a default.nix, all in one pass
    validPkgs =
      prev.lib.filterAttrs (
        name: type: type == "directory" && builtins.pathExists (pkgsDir + "/${name}/default.nix")
      )
      dirEntries;
    # Get the names of the valid packages
    packageNames = builtins.attrNames validPkgs;
  in
    # Build only the valid packages
    prev.lib.genAttrs packageNames (name: prev.callPackage (pkgsDir + "/${name}") {});

  # Package fixes
  pamixer = import ./pamixer.nix;
  # Promote npm packages (e.g., nx-latest) to top-level pkgs attributes
  npm-packages = import ./npm-packages.nix;

  # Essential tools
  nh = inputs.nh.overlays.default;
  nur = inputs.nur.overlays.default;

  # === Platform-Specific Overlays ===

  # Linux-only (niri is an input, waybar/swww are modifications)
  niri = mkConditional isLinux inputs.niri.overlays.niri;
  waybar = mkConditional isLinux (import ./waybar.nix {inherit inputs;});
  swww = mkConditional isLinux (import ./swww.nix {inherit inputs;});
  nvidia-patch =
    mkConditional (
      isLinux && inputs ? nvidia-patch
    )
    inputs.nvidia-patch.overlays.default;
}
