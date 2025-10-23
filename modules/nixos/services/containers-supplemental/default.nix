# Supplemental Container Services
# Services that don't have native NixOS modules yet
# These remain as containers: Homarr, Wizarr, Doplarr, ComfyUI, Cal.com
#
# ⚠️  SECURITY WARNING: SECRETS MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Services like Cal.com, Doplarr require secrets (API keys, passwords, etc.)
# This module does NOT provide default secrets for security reasons.
#
# You MUST configure secrets before enabling these services:
# - Cal.com: requires nextauthSecret, calendarEncryptionKey, dbPassword
# - Doplarr: requires discordToken, sonarrApiKey, radarrApiKey
#
# For development: Set secrets directly in your host configuration
# For production: Use sops-nix for encrypted secrets management
#
# See docs/SECRETS-MANAGEMENT.md for detailed implementation guide.
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types mkDefault;

  cfg = config.host.services.containersSupplemental;
in {
  imports = [
    ./services/homarr.nix
    ./services/wizarr.nix
    ./services/doplarr.nix
    ./services/comfyui.nix
    ./services/calcom.nix
    ./services/janitorr.nix
  ];

  options.host.services.containersSupplemental = {
    enable = mkEnableOption "supplemental container services";

    configPath = mkOption {
      type = types.str;
      default = "/var/lib/containers/supplemental";
      description = "Path to store container configurations.";
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Timezone for all containers.";
    };

    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "User ID for container processes.";
    };

    gid = mkOption {
      type = types.int;
      default = 100;
      description = "Group ID for container processes.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
      dockerCompat = mkDefault (!config.virtualisation.docker.enable);
      dockerSocket.enable = mkDefault (!config.virtualisation.docker.enable);
    };

    virtualisation.oci-containers.backend = "podman";

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath} 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];
  };
}
