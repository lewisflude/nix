# Restic Backup Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  restic = {
    enable = mkEnableOption "Restic backup integration";

    backups = mkOption {
      type = types.attrsOf (
        types.submodule (_: {
          options = {
            enable = mkEnableOption "Enable this Restic backup job";
            path = mkOption {
              type = types.str;
              description = "Path to back up.";
              example = "/home/user/Documents";
            };
            repository = mkOption {
              type = types.str;
              description = "Restic repository URL.";
              example = "sftp:user@host:/path/to/repo";
            };
            passwordFile = mkOption {
              type = types.str;
              description = "Path to the file containing the repository password.";
              example = "/run/secrets/restic-password";
            };
            timer = mkOption {
              type = types.str;
              default = "daily";
              description = "Timer specification for the backup job (e.g., 'daily').";
              example = "daily";
            };
            user = mkOption {
              type = types.str;
              default = "root";
              description = "User account that owns the backup job.";
              example = "root";
            };
            extraOptions = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Additional CLI options passed to restic.";
              example = [ "--verbose" ];
            };
            initialize = mkOption {
              type = types.bool;
              default = false;
              description = "Initialise the repository if it does not yet exist.";
              example = true;
            };
            createWrapper = mkOption {
              type = types.bool;
              default = false;
              description = "Create a security wrapper for restic to access protected paths.";
              example = true;
            };
          };
        })
      );
      default = { };
      description = "Per-backup job configuration for Restic.";
    };

    restServer = {
      enable = mkEnableOption "Restic REST server";
      port = mkOption {
        type = types.int;
        default = 8000;
        description = "Port the Restic REST server listens on.";
        example = 8000;
      };
      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional flags for restic-rest-server.";
        example = [ "--no-auth" ];
      };
      htpasswdFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to an htpasswd file for server authentication.";
        example = "/var/lib/restic/.htpasswd";
      };
    };
  };
}
