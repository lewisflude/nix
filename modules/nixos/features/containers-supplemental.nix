# Bridge module: Maps host.features.containersSupplemental to host.services.containersSupplemental
# This allows host configurations to use the features interface
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.containersSupplemental;
in
{
  config = mkIf cfg.enable {
    # Map features to services
    host.services.containersSupplemental = {
      enable = true;
      uid = cfg.uid or 1000;
      gid = cfg.gid or 100;
      homarr = cfg.homarr or { };
      wizarr = cfg.wizarr or { };
      janitorr = cfg.janitorr or { };
      doplarr = cfg.doplarr or { };
      comfyui = cfg.comfyui or { };
      calcom = cfg.calcom or { };
    };
  };
}
