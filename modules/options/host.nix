# Host options for the dendritic pattern.
# Reserved for genuine per-host *hardware* parameters. Identity (username, email,
# full name) is shared through the top-level options in modules/meta.nix, per
# dendritic invariant 5 — not round-tripped through a lower-level `host` option.
# Toggling whether a feature is active should be done by importing or omitting the
# module — not by an enable flag here. See: https://github.com/mightyiam/dendritic
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  flake.modules.nixos.hostOptions = {
    options.host = {
      hardware.renderDevice = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "DRM render device path for GPU selection";
      };
    };
  };
}
