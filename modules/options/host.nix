# Host options for the dendritic pattern.
# Reserved for per-host *parameters* (identity, paths, ACME emails). Toggling whether
# a feature is active should be done by importing or omitting the module — not by an
# enable flag here. See: https://github.com/mightyiam/dendritic
{ lib, ... }:
let
  inherit (lib) mkOption types;

  mkCommonOptions = {
    username = mkOption {
      type = types.str;
      description = "Primary user's username";
    };

    hostname = mkOption {
      type = types.str;
      description = "System hostname";
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
