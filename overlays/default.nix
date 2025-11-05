# Overlay system with selective application
#
# PURPOSE:
# This file centralizes all package overlays for the Nix configuration. Overlays are
# organized by priority and platform, allowing selective application based on the
# target system architecture.
#
# OVERLAY APPLICATION:
# Overlays are applied in two ways:
# 1. Internally: via functionsLib.mkOverlays in lib/system-builders.nix and flake-parts/core.nix
# 2. Externally: via flake.overlays.default (exported for other flakes to consume)
#
# The order of overlays matters as later overlays can override earlier ones.
#
# PERFORMANCE CONSIDERATIONS:
# Some overlays modify build flags (pamixer, mpd-fix) which cause cache misses.
# Others (webkitgtk-compat, npm-packages) are pure aliases/additions with no impact.
# See individual overlay files for detailed performance notes.
#
# ADDING NEW OVERLAYS:
# 1. Create overlay file in this directory (e.g., my-overlay.nix)
# 2. Import it in this file (e.g., `my-overlay = import ./my-overlay.nix;`)
# 3. Add it to the appropriate section (Core, Application, Platform-Specific)
# 4. Document performance impact and removal conditions in the overlay file
#
# REMOVAL GUIDELINES:
# - Core overlays: Rarely removed (unstable, localPkgs)
# - Application overlays: Can be removed when fixes are upstreamed
# - Platform overlays: Only active on specific platforms
{
  inputs,
  system,
}:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";

  # Helper to make conditional overlays
  # Returns the overlay if condition is true, otherwise returns a no-op overlay
  mkConditional = condition: overlay: if condition then overlay else (_final: _prev: { });
in
rec {
  # === Core Overlays (always applied) ===

  # Unstable packages namespace
  unstable = _final: prev: {
    unstable = import (inputs.nixpkgs or (throw "nixpkgs input is required")) {
      inherit system;
      inherit (prev) config;
    };
  };

  # === Application Overlays (always applied) ===
  # These overlays provide custom packages and fixes

  # Node.js version alias (must come early to affect all subsequent overlays)
  # Ensures all packages use nodejs_24 instead of the default nodejs to prevent conflicts
  nodejs-alias = import ./nodejs-alias.nix;

  # Auto-import all packages from ../pkgs (each subdirectory with a default.nix)
  # This allows easy addition of new custom packages by creating a directory
  # in pkgs/ with a default.nix file
  localPkgs =
    _final: prev:
    let
      pkgsDir = ../pkgs;
      # Read all entries in the pkgs directory
      dirEntries = builtins.readDir pkgsDir;
      # Filter for entries that are directories AND have a default.nix, all in one pass
      validPkgs = prev.lib.filterAttrs (
        name: type: type == "directory" && builtins.pathExists (pkgsDir + "/${name}/default.nix")
      ) dirEntries;
      # Get the names of the valid packages
      packageNames = builtins.attrNames validPkgs;
    in
    # Build only the valid packages
    # Pass inputs only to packages that explicitly need it (like ghostty)
    prev.lib.genAttrs packageNames (
      name:
      if name == "ghostty" then
        prev.callPackage (pkgsDir + "/${name}") { inherit inputs; }
      else
        prev.callPackage (pkgsDir + "/${name}") { }
    );

  # Package fixes and compatibility overlays
  # These overlays modify existing packages to fix build issues or provide compatibility
  pamixer = import ./pamixer.nix; # Fixes ICU 76.1+ compatibility (C++17 flag)
  mpd-fix = import ./mpd-fix.nix; # Fixes MPD io_uring issue on kernel 6.14.11
  npm-packages = import ./npm-packages.nix; # Promotes NPM packages to top-level (e.g., nx-latest)
  webkitgtk-compat = import ./webkitgtk-compat.nix; # Compatibility alias for removed webkitgtk

  # Essential tools (conditional on input existence)
  nh =
    if inputs ? nh && inputs.nh ? overlays then inputs.nh.overlays.default else (_final: _prev: { });
  nur =
    if inputs ? nur && inputs.nur ? overlays then inputs.nur.overlays.default else (_final: _prev: { });

  # Infrastructure visualization (conditional on input existence)
  nix-topology =
    if inputs ? nix-topology && inputs.nix-topology ? overlays then
      inputs.nix-topology.overlays.default
    else
      (_final: _prev: { });

  # === Latest Flake Packages ===
  # Code editors with bleeding-edge features
  flake-editors = _final: prev: {
    helix =
      if
        inputs ? helix
        && inputs.helix ? packages
        && inputs.helix.packages ? ${system}
        && inputs.helix.packages.${system} ? default
      then
        inputs.helix.packages.${system}.default
      else
        prev.helix;
    # Using stable zed-editor from nixpkgs instead (for cached binaries)
    # zed-editor = inputs.zed-editor.packages.${system}.default or prev.zed-editor;
  };

  # Rust toolchain overlay (provides latest Rust, rust-analyzer, etc.)
  rust-overlay =
    if inputs ? rust-overlay && inputs.rust-overlay ? overlays then
      inputs.rust-overlay.overlays.default
    else
      (_final: _prev: { });

  # Git tools with latest features
  flake-git-tools = _final: prev: {
    lazygit =
      if
        inputs ? lazygit
        && inputs.lazygit ? packages
        && inputs.lazygit.packages ? ${system}
        && inputs.lazygit.packages.${system} ? default
      then
        inputs.lazygit.packages.${system}.default
      else
        prev.lazygit;
  };

  # CLI tools with latest improvements
  flake-cli-tools = _final: prev: {
    atuin =
      if
        inputs ? atuin
        && inputs.atuin ? packages
        && inputs.atuin.packages ? ${system}
        && inputs.atuin.packages.${system} ? default
      then
        inputs.atuin.packages.${system}.default
      else
        prev.atuin;
  };

  # === Platform-Specific Overlays ===

  # Audio production packages (Linux-only)
  audio-nix = mkConditional (isLinux && inputs ? audio-nix && inputs.audio-nix ? overlays) (
    if inputs ? audio-nix && inputs.audio-nix ? overlays then
      inputs.audio-nix.overlays.default
    else
      (_final: _prev: { })
  );

  # Linux-only
  niri = mkConditional (isLinux && inputs ? niri && inputs.niri ? overlays) (
    if inputs ? niri && inputs.niri ? overlays then inputs.niri.overlays.niri else (_final: _prev: { })
  );
  nvidia-patch = mkConditional (isLinux && inputs ? nvidia-patch && inputs.nvidia-patch ? overlays) (
    if inputs ? nvidia-patch && inputs.nvidia-patch ? overlays then
      inputs.nvidia-patch.overlays.default
    else
      (_final: _prev: { })
  );
}
