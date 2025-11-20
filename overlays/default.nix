# Package overlays
# Simplified - only essential customizations
{ inputs, system }:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";
in
{
  # Local custom packages
  localPkgs = _final: prev: {
    cursor = prev.callPackage (../pkgs + "/cursor") { };
  };

  # Custom NPM packages
  npm-packages = import ./npm-packages.nix;

  # Nix helper tool overlay
  nh = if inputs ? nh && inputs.nh ? overlays
    then inputs.nh.overlays.default
    else (_final: _prev: { });

  # Network topology visualization
  nix-topology = if inputs ? nix-topology && inputs.nix-topology ? overlays
    then inputs.nix-topology.overlays.default
    else (_final: _prev: { });

  # Use stable zed-editor from nixpkgs
  flake-editors = _final: prev: {
    inherit (prev) zed-editor;
  };

  # Rust toolchains from fenix (better than nixpkgs)
  fenix-overlay = if inputs ? fenix && inputs.fenix ? overlays
    then inputs.fenix.overlays.default
    else (_final: _prev: { });

  # Lazygit from flake input
  flake-git-tools = _final: prev:
    if inputs ? lazygit && inputs.lazygit ? packages && inputs.lazygit.packages ? ${system}
    then { lazygit = inputs.lazygit.packages.${system}.default; }
    else { inherit (prev) lazygit; };

  # Atuin from flake input
  flake-cli-tools = _final: prev:
    if inputs ? atuin && inputs.atuin ? packages && inputs.atuin.packages ? ${system}
    then { atuin = inputs.atuin.packages.${system}.default; }
    else { inherit (prev) atuin; };

  # Niri compositor (Linux only)
  niri = if isLinux && inputs ? niri && inputs.niri ? overlays
    then inputs.niri.overlays.niri
    else (_final: _prev: { });

  # Optimization: Disable direnv tests that fail on Darwin
  direnv-optimization = _final: prev: {
    direnv = prev.direnv.overrideAttrs (_old: {
      doCheck = false;
    });
  };
}
