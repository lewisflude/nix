# Niri Keybindings - Main Entry Point
# Combines all keybinding categories
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) foldl' recursiveUpdate;

  # List all keybind modules to merge
  # Order doesn't matter - recursiveUpdate handles conflicts by last-write-wins
  keybindModules = [
    (import ./window-management.nix { inherit pkgs lib; })
    (import ./workspace.nix { })
    (import ./column-layout.nix { })
    (import ./window-navigation.nix { })
    (import ./media.nix { inherit config pkgs lib; })
    (import ./screenshots.nix { inherit pkgs lib; })
    (import ./launchers.nix { inherit config pkgs lib; })
    (import ./system.nix { inherit pkgs lib; })
    (import ./monitor.nix { inherit pkgs lib; })
    (import ./mouse.nix { })
  ];
in
# Merge all keybind modules into a single attrset
foldl' recursiveUpdate { } keybindModules
