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
    enable = mkEnableOption "home server and self-hosting" // {
      example = true;
    };
    homeAssistant = mkEnableOption "Home Assistant home automation" // {
      example = true;
    };
    fileSharing = mkEnableOption "Samba/NFS file sharing" // {
      example = true;
    };
    backups = mkEnableOption "Restic backup services" // {
      example = true;
    };
  };
}
