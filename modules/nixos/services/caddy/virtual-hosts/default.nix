# Virtual Hosts - Main Entry Point
# Combines all virtual host categories
{
  lib,
  constants,
  ...
}:
lib.mergeAttrsList [
  (import ./infrastructure.nix { inherit lib constants; })
  (import ./media.nix { inherit lib constants; })
  (import ./arr-stack.nix { inherit lib constants; })
  (import ./downloads.nix { inherit lib constants; })
  (import ./ai.nix { inherit lib constants; })
  (import ./gaming.nix { inherit lib constants; })
  (import ./misc.nix { inherit lib constants; })
]
