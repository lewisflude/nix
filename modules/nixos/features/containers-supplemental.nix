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

    host.services.containersSupplemental = {
      enable = true;
      inherit (cfg) uid;
      inherit (cfg) gid;
      inherit (cfg) homarr;
      inherit (cfg) wizarr;
      inherit (cfg) janitorr;
      inherit (cfg) doplarr;
      inherit (cfg) comfyui;
      inherit (cfg) calcom;
      inherit (cfg) profilarr;
      inherit (cfg) termix;
      inherit (cfg) cleanuparr;
    };
  };
}
