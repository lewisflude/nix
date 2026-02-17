# Host options for the dendritic pattern
# Defines host.* options that feature modules set when imported
# Home-manager modules can read these via osConfig/systemConfig
{ config, lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;

  # Shared options between NixOS and Darwin
  mkCommonOptions = {
    username = mkOption {
      type = types.str;
      description = "Primary user's username";
    };

    useremail = mkOption {
      type = types.str;
      default = "";
      description = "Primary user's email address";
    };

    hostname = mkOption {
      type = types.str;
      description = "System hostname";
    };

    system = mkOption {
      type = types.str;
      description = "System architecture";
    };

    features = {
      gaming.enable = mkEnableOption "gaming platforms and optimizations";
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

    config.host = lib.mkIf (config.options.host.username.isDefined or false) {
      system = lib.mkDefault "x86_64-linux";
    };
  };

  flake.modules.darwin.hostOptions = {
    options.host = mkCommonOptions;

    config.host = {
      system = lib.mkDefault "aarch64-darwin";
    };
  };
}
