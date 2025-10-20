# Bridge module: Maps host.features.containersSupplemental to host.services.containersSupplemental
# This allows host configurations to use the features interface
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.features.containersSupplemental or {};
in {
  config = mkIf (cfg.enable or false) {
    # Map features to services
    host.services.containersSupplemental = {
      enable = true;
      homarr = cfg.homarr or {};
      wizarr = cfg.wizarr or {};
      doplarr = cfg.doplarr or {};
      comfyui = cfg.comfyui or {};
      calcom = cfg.calcom or {};
    };
  };
}
