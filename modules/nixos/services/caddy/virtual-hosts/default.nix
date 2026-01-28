# Virtual Hosts - Main Entry Point
# Combines all virtual host categories
{
  lib,
  ...
}:
lib.mergeAttrsList [
  (import ./infrastructure.nix { inherit lib; })
  (import ./media.nix { inherit lib; })
  (import ./arr-stack.nix { inherit lib; })
  (import ./downloads.nix { inherit lib; })
  (import ./ai.nix { inherit lib; })
  (import ./gaming.nix { inherit lib; })
  (import ./misc.nix { inherit lib; })
]
