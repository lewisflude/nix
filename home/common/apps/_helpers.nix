{
  lib,
  system,
}:
let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  inherit platformLib;
}
