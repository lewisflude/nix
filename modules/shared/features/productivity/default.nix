{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.productivity;
in
{
  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.resume -> cfg.enable;
        message = "Resume generation requires productivity feature to be enabled";
      }
    ];
  };
}
