{
  lib,
  system,
  username,
  ...
}: let
  platformLib = (import ../../../lib/functions.nix {inherit lib;}).withSystem system;
  secretsDir = "${platformLib.dataDir username}/sops-nix";
in {
  system.activationScripts.setupSOPSAge = {
    text = ''
      install -d -m 700 -o root -g wheel /var/lib/sops-nix
      install -d -m 700 -o ${username} -g staff ${secretsDir}
    '';
  };
}
