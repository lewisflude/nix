# Host options for the dendritic pattern
# Defines host.* options that feature modules set when imported
# Home-manager modules can read these via osConfig/systemConfig
{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;

  # Shared options between NixOS and Darwin
  mkCommonOptions = {
    username = mkOption {
      type = types.str;
      description = "Primary user's username";
    };

    hostname = mkOption {
      type = types.str;
      description = "System hostname";
    };

    features = {
      desktop.autoLogin = {
        enable = mkEnableOption "auto-login";
        user = mkOption {
          type = types.str;
          default = "";
          description = "User to auto-login";
        };
      };
    };

    services.caddy = {
      enable = mkEnableOption "Caddy reverse proxy";
      email = mkOption {
        type = types.str;
        default = "";
        description = "Email for ACME certificates";
      };
    };
  };
in
{
  flake.modules.nixos.hostOptions = {
    options.host = mkCommonOptions // {
      hardware.renderDevice = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "DRM render device path for GPU selection";
      };
    };

  };

  flake.modules.darwin.hostOptions = {
    options.host = mkCommonOptions;
  };
}
