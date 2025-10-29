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
    # Pass inputs only to packages that explicitly need it (like ghostty)
    prev.lib.genAttrs packageNames (
      name:
        if name == "ghostty"
        then prev.callPackage (pkgsDir + "/${name}") {inherit inputs;}
        else prev.callPackage (pkgsDir + "/${name}") {}
    );

  # Package fixes
  pamixer = import ./pamixer.nix;
  mpd-fix = import ./mpd-fix.nix;
  # Promote npm packages (e.g., nx-latest) to top-level pkgs attributes
  npm-packages = import ./npm-packages.nix;
  # Compatibility overlay for removed webkitgtk package
  webkitgtk-compat = import ./webkitgtk-compat.nix;

  # Essential tools
  nh = inputs.nh.overlays.default;
  nur = inputs.nur.overlays.default;

  # === Latest Flake Packages ===
  # Code editors with bleeding-edge features
  flake-editors = _final: prev: {
    helix = inputs.helix.packages.${system}.default or prev.helix;
    # Using stable zed-editor from nixpkgs instead (for cached binaries)
    # zed-editor = inputs.zed-editor.packages.${system}.default or prev.zed-editor;
  };

  # Rust toolchain overlay (provides latest Rust, rust-analyzer, etc.)
  rust-overlay = inputs.rust-overlay.overlays.default;

  # Git tools with latest features
  flake-git-tools = _final: prev: {
    lazygit = inputs.lazygit.packages.${system}.default or prev.lazygit;
  };

  # CLI tools with latest improvements
  flake-cli-tools = _final: prev: {
    atuin = inputs.atuin.packages.${system}.default or prev.atuin;
  };

  # === Platform-Specific Overlays ===

  # Audio production packages (Linux-only)
  audio-nix = mkConditional isLinux inputs.audio-nix.overlays.default;

  # Linux-only
  niri = mkConditional isLinux inputs.niri.overlays.niri;
  nvidia-patch =
    mkConditional (
      isLinux && inputs ? nvidia-patch
    )
    inputs.nvidia-patch.overlays.default;
}
