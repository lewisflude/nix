# Package overlays
# Simplified - only essential customizations
{ inputs, system }:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";
in
{
  # Nix helper tool overlay
  nh =
    if inputs ? nh && inputs.nh ? overlays then inputs.nh.overlays.default else (_final: _prev: { });

  # Network topology visualization
  nix-topology =
    if inputs ? nix-topology && inputs.nix-topology ? overlays then
      inputs.nix-topology.overlays.default
    else
      (_final: _prev: { });

  # Use stable zed-editor from nixpkgs
  flake-editors = _final: prev: {
    inherit (prev) zed-editor;
  };

  # Rust toolchains from fenix (better than nixpkgs)
  fenix-overlay =
    if inputs ? fenix && inputs.fenix ? overlays then
      inputs.fenix.overlays.default
    else
      (_final: _prev: { });

  # Lazygit - using nixpkgs version for binary cache
  flake-git-tools = _final: prev: {
    inherit (prev) lazygit;
  };

  # Atuin - using nixpkgs version for binary cache
  flake-cli-tools = _final: prev: {
    inherit (prev) atuin;
  };

  # Niri compositor (Linux only)
  niri =
    if isLinux && inputs ? niri && inputs.niri ? overlays then
      inputs.niri.overlays.niri
    else
      (_final: _prev: { });

  # ComfyUI overlay (native Nix package, replaces Docker container)
  comfyui =
    if inputs ? comfyui && inputs.comfyui ? overlays && inputs.comfyui.overlays ? default then
      inputs.comfyui.overlays.default
    else if inputs ? comfyui && inputs.comfyui ? packages && inputs.comfyui.packages ? ${system} then
      (_final: _prev: { comfyui = inputs.comfyui.packages.${system}.default or _prev.hello; })
    else
      (_final: _prev: { });

  # Claude Code - Pre-built binaries from Anthropic (via overlay)
  claude-code-overlay =
    if inputs ? claude-code-overlay && inputs.claude-code-overlay ? overlays then
      inputs.claude-code-overlay.overlays.default
    else
      (_final: _prev: { });

}
