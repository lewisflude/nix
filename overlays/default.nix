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

  # Zed editor: Use nixpkgs version (Zed flake currently broken - cargo-about@0.8.2 dependency issue)
  # This allows binary cache hits when available, providing fast, reliable installs
  # The nixpkgs version can use cache.nixos.org when cached
  # TODO: Re-enable Zed flake when cargo-about dependency issue is resolved
  flake-editors = _final: prev: {
    # Use nixpkgs version - can use cache.nixos.org when available
    # Removed doCheck=false overlay to allow cache hits
    inherit (prev) zed-editor;
  };
  # flake-editors =
  #   final: prev:
  #   if inputs ? zed && inputs.zed ? packages && inputs.zed.packages ? ${system} then
  #     {
  #       # Use Zed flake - likely has CI cache from zed.cachix.org
  #       zed-editor = inputs.zed.packages.${system}.default;
  #     }
  #   else
  #     {
  #       # Fallback to nixpkgs version - can use cache.nixos.org when available
  #       inherit (prev) zed-editor;
  #     };

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

  # nixpkgs-xr overlay (VR/AR/XR packages - Linux only)
  nixpkgs-xr =
    if isLinux && inputs ? nixpkgs-xr && inputs.nixpkgs-xr ? overlays then
      inputs.nixpkgs-xr.overlays.default
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

  # Audio.nix overlay (Bitwig Studio and audio plugins)
  # Wrapped with webkitgtk compatibility fix
  audio-nix =
    if
      isLinux && inputs ? audio-nix && inputs.audio-nix ? overlays && inputs.audio-nix.overlays ? default
    then
      # Wrap the audio.nix overlay to add webkitgtk compatibility
      final: super:
      let
        # First apply webkitgtk compatibility
        superWithWebkit =
          super // (if super ? webkitgtk_6_0 then { webkitgtk = super.webkitgtk_6_0; } else { });
        # Then apply the audio.nix overlay
        audioNixOverlay = inputs.audio-nix.overlays.default;
      in
      audioNixOverlay final superWithWebkit
    else
      (_final: _prev: { });

  # Claude Code overlay disabled due to runtime errors
  # The overlay version (2.0.55) has Bun Segmenter initialization errors
  # Using nixpkgs version (2.0.54) instead
  # claude-code-overlay =
  #   if inputs ? claude-code-overlay && inputs.claude-code-overlay ? overlays then
  #     inputs.claude-code-overlay.overlays.default
  #   else
  #     (_final: _prev: { });

  # LLM agents - use pre-built binaries from llm-agents.nix
  # Daily builds with binary cache at https://cache.numtide.com
  llm-agents =
    _final: _prev:
    if
      inputs ? llm-agents && inputs.llm-agents ? packages && inputs.llm-agents.packages ? ${system}
    then
      inputs.llm-agents.packages.${system}
    else
      { };

}
