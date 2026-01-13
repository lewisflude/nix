# Virtual Hosts - Main Entry Point
# Combines all virtual host categories
{
  lib,
  ...
}:
let
  inherit (lib) recursiveUpdate;
in
recursiveUpdate
  (recursiveUpdate (recursiveUpdate
    (recursiveUpdate (recursiveUpdate (import ./infrastructure.nix { inherit lib; }) (
      import ./media.nix { inherit lib; }
    )) (import ./arr-stack.nix { inherit lib; }))
    (import ./downloads.nix { inherit lib; })
  ) (import ./ai.nix { inherit lib; }))
  (recursiveUpdate (import ./gaming.nix { inherit lib; }) (import ./misc.nix { inherit lib; }))
