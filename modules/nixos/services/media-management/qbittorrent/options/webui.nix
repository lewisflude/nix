{
  lib,
  constants,
  ...
}:
with lib;
{
  webUI = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          username = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              WebUI username (plain text). Ignored when useSops is true.
              When useSops=true, credentials are read from SOPS secrets at runtime.
            '';
          };
          password = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              WebUI password (PBKDF2 format, plain text). Ignored when useSops is true.
              When useSops=true, credentials are read from SOPS secrets at runtime.
            '';
          };
          useSops = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Whether to use SOPS secrets for WebUI credentials.
              Secrets must be defined in secrets.yaml:
              - qbittorrent/webui/username
              - qbittorrent/webui/password (in PBKDF2 format)

              When enabled, credentials are injected at service start from /run/secrets.
              This follows best practices: secrets are never stored in the Nix store.
            '';
          };
          port = mkOption {
            type = types.port;
            default = constants.ports.services.qbittorrent;
            description = "WebUI port";
          };
          bindAddress = mkOption {
            type = types.str;
            default = "*";
            description = "WebUI bind address (* for all interfaces, or specific IP)";
          };
          alternativeUIEnabled = mkOption {
            type = types.bool;
            default = false;
            description = "Enable alternative WebUI (e.g., vuetorrent)";
          };
          rootFolder = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Root folder for alternative WebUI (absolute path). If null and alternativeUIEnabled is true, uses vuetorrent from Nix store";
          };
        };
      }
    );
    default = null;
    description = "WebUI configuration";
  };
}
