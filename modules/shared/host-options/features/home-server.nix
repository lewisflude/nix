# Home Server Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  homeServer = {
    enable = mkEnableOption "home server and self-hosting";
    fileSharing = mkEnableOption "Samba/NFS file sharing";
    backups = mkEnableOption "Restic backup services";
  };
}
