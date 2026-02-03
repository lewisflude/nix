# Home Manager SOPS configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.sops
{ config, ... }:
{
  flake.modules.homeManager.sops = { lib, pkgs, config, ... }:
    let
      isDarwin = pkgs.stdenv.isDarwin;
      homeDir = if isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";
      dataDir = if isDarwin then "${homeDir}/Library/Application Support" else "${homeDir}/.local/share";
      keyFilePath = if isDarwin then "${dataDir}/sops-nix/key.txt" else "/var/lib/sops-nix/key.txt";
    in
    {
      sops.age = {
        keyFile = keyFilePath;
        sshKeyPaths = [ ];
      };
    };
}
