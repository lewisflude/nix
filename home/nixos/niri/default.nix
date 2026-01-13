# Niri Compositor Configuration - Main File
# Combines all niri configuration modules
{
  pkgs,
  config,
  lib,
  inputs,
  system,
  themeLib,
  ...
}:
let
  themeConstants = import ../theme-constants.nix {
    inherit lib themeLib;
  };
  # Use overlay packages to ensure mesa dependencies match system nixpkgs
  inherit (pkgs) xwayland-satellite-unstable niri-unstable;
  xwayland-satellite = xwayland-satellite-unstable;

  packagesList = import ./packages.nix {
    inherit pkgs inputs system;
  };
  input = import ./input.nix { };
  outputs = import ./outputs.nix { };
  layout = import ./layout.nix { inherit themeConstants; };
  window-rules = import ./window-rules.nix { };
  animations = import ./animations.nix { };
  startup = import ./startup.nix {
    inherit
      config
      pkgs
      inputs
      system
      ;
  };
  binds = import ./keybinds/default.nix {
    inherit config pkgs lib;
  };
in
{
  home.packages = packagesList;

  # Make workspace creation script available
  home.file.".local/bin/create-niri-workspaces" = {
    source = ../scripts/create-niri-workspaces.sh;
    executable = true;
  };
  imports = [
  ];
  programs.niri = {
    package = niri-unstable;
    settings = {
      xwayland-satellite = {
        enable = true;
        path = "${lib.getExe xwayland-satellite}";
      };
      # Force NVIDIA RTX 4090 as the primary render device
      # Use renderD128 (render node) for optimal performance on multi-GPU systems
      # This ensures Niri doesn't try to use the Intel iGPU for rendering
      debug = {
        render-drm-device = "/dev/dri/renderD128";
      };
    }
    // input
    // outputs
    // layout
    // window-rules
    // animations
    // startup
    // {
      inherit binds;
    };
  };
}
