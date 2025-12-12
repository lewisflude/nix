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

  # Use zed-editor from official flake (includes Cachix for faster builds)
  # TEMPORARILY DISABLED: zed flake has build issues with cargo-about@0.8.2 dependency
  # Using nixpkgs version until zed flake is fixed or updated
  # TODO: Re-enable when zed flake build issues are resolved
  flake-editors = _final: prev: {
    inherit (prev) zed-editor;
  };
  # flake-editors =
  #   final: prev:
  #   if inputs ? zed && inputs.zed ? packages && inputs.zed.packages ? ${system} then
  #     {
  #       zed-editor = inputs.zed.packages.${system}.default;
  #     }
  #   else
  #     {
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

}
