{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.navidrome = {
    enable = mkEnableOption "Navidrome music server" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Navidrome" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.navidrome.enable) {
    services.navidrome = {
      enable = true;
      openFirewall = false; # We manage it manually to use our constants
      inherit (cfg) user;
      inherit (cfg) group;
      settings = {
        Port = constants.ports.services.navidrome;
        Address = "0.0.0.0";
        MusicFolder = "${cfg.dataPath}/media/music";
        DataFolder = "/var/lib/navidrome";
        EnableInsightsCollector = false;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.navidrome.openFirewall [
      constants.ports.services.navidrome
    ];

    systemd.services.navidrome = {
      environment = {
        TZ = cfg.timezone;
      };
    };

    users.users.${cfg.user}.extraGroups = [
      "audio"
    ];
  };
}
