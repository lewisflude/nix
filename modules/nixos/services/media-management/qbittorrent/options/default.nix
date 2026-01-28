{
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
  qbittorrentOptions = {
    enable = mkEnableOption "qBittorrent BitTorrent client" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for qBittorrent" // {
      default = true;
    };

    categories = mkOption {
      type = types.nullOr (types.attrsOf types.str);
      default = null;
      description = "Category save paths";
    };

    incompleteDownloadPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path for incomplete downloads (use fast SSD for staging)";
    };

    defaultSavePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default folder for completed torrents";
    };

    maxRatio = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "Maximum seeding ratio (null = unlimited)";
    };

    maxInactiveSeedingTime = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Maximum inactive seeding time in minutes (null = unlimited)";
    };

    shareLimitAction = mkOption {
      type = types.enum [
        "Stop"
        "Remove"
        "DeleteFiles"
      ];
      default = "Stop";
      description = "Action when share limits are reached";
    };

    uploadSpeedLimit = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Upload speed limit in KB/s (null = unlimited)";
    };
  };
in
{
  options.host.services.mediaManagement.qbittorrent =
    qbittorrentOptions
    // (import ./webui.nix { inherit lib constants; })
    // (import ./bittorrent.nix { inherit lib; })
    // (import ./performance.nix { inherit lib; });
}
