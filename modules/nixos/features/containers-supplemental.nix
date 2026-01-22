# Bridge module: Forwards host.features.containersSupplemental to host.services.containersSupplemental
# TODO: Consolidate feature and service options to eliminate this indirection
# See docs/reference/REFACTORING_EXAMPLES.md for the recommended pattern
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
      inherit (cfg)
        uid
        gid
        homarr
        wizarr
        janitorr
        doplarr
        comfyui
        calcom
        profilarr
        termix
        cleanuparr
        ;
    };
  };
}
