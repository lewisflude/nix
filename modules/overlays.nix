# Overlay accumulator + shared cross-cutting overlays.
#
# Feature-specific overlays live with their feature module (e.g. wivrn-cuda
# in modules/vr.nix). To add an overlay, write `overlays.<name> = final: prev: {...}`
# in the relevant module. System-conditional overlays should branch internally on
# `prev.stdenv.hostPlatform.isLinux` etc. rather than being filtered externally.
#
# Composition order is alphabetical by attribute name, so name-prefix to control
# precedence (composeExtensions applies later overlays last).
{
  lib,
  config,
  inputs,
  ...
}:
{
  options.overlays = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Map of overlay name → overlay function. Contributed by feature modules.";
  };

  options.overlaysForSystem = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = _system: builtins.attrValues config.overlays;
    description = ''
      Returns the full list of contributed overlays. The `system` arg is retained
      for backward compatibility but unused — overlays self-branch on hostPlatform.
    '';
  };

  config.flake.overlays.default =
    final: prev:
    if !(prev ? stdenv) then
      { } # nix flake check calls overlay {} {} — noop without real nixpkgs
    else
      let
        overlayList = builtins.attrValues config.overlays;
      in
      (lib.foldl' lib.composeExtensions (_: _: { }) overlayList) final prev;

  # ─────────────────────────────────────────────────────────────────────
  # Shared / cross-cutting overlays (no single feature owner)
  # ─────────────────────────────────────────────────────────────────────
  config.overlays = {
    # NUR — community packages, used wherever
    nur = inputs.nur.overlays.default;

    # ComfyUI: upstream exposes either overlays.default or packages.<system>.default
    comfyui =
      final: prev:
      let
        inherit (prev.stdenv.hostPlatform) system;
      in
      if inputs.comfyui ? overlays && inputs.comfyui.overlays ? default then
        inputs.comfyui.overlays.default final prev
      else if inputs.comfyui.packages ? ${system} then
        { comfyui = inputs.comfyui.packages.${system}.default; }
      else
        { };
  };
}
