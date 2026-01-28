# Feature Options - Main File
# Imports and combines all feature option definitions
{
  lib,
  ...
}:
let
  development = import ./development.nix { inherit lib; };
  gaming = import ./gaming.nix { inherit lib; };
  vr = import ./vr.nix { inherit lib; };
  virtualisation = import ./virtualisation.nix { inherit lib; };
  homeServer = import ./home-server.nix { inherit lib; };
  desktop = import ./desktop.nix { inherit lib; };
  restic = import ./restic.nix { inherit lib; };
  productivity = import ./productivity.nix { inherit lib; };
  media = import ./media.nix { inherit lib; };
  security = import ./security.nix { inherit lib; };
  aiTools = import ./ai-tools.nix { inherit lib; };
in
{
  options.host.features =
    development
    // gaming
    // vr
    // virtualisation
    // homeServer
    // desktop
    // restic
    // productivity
    // media
    // security
    // aiTools;
}
