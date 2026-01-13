# Niri Keybindings - Main Entry Point
# Combines all keybinding categories
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) recursiveUpdate;
in
recursiveUpdate (recursiveUpdate
  (recursiveUpdate
    (recursiveUpdate
      (recursiveUpdate (recursiveUpdate
        (recursiveUpdate (recursiveUpdate (import ./window-management.nix { inherit pkgs lib; }) (
          import ./workspace.nix { }
        )) (import ./column-layout.nix { }))
        (import ./window-navigation.nix { })
      ) (import ./media.nix { inherit config pkgs lib; }))
      (import ./screenshots.nix { inherit pkgs lib; })
    )
    (import ./launchers.nix { inherit config pkgs lib; })
  )
  (import ./system.nix { inherit pkgs lib; })
) (recursiveUpdate (import ./monitor.nix { inherit pkgs; }) (import ./mouse.nix { }))
