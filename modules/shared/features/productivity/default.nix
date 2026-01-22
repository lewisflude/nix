{
  config,
  # lib,
  ...
}:
let
  cfg = config.host.features.productivity;
in
{
  config = {
    assertions = [
      {
        assertion = cfg.resume -> cfg.enable;
        message = "Resume generation requires productivity feature to be enabled";
      }
      {
        assertion = cfg.office -> cfg.enable;
        message = "Office suite requires productivity feature to be enabled";
      }
      {
        assertion = cfg.notes -> cfg.enable;
        message = "Note taking requires productivity feature to be enabled";
      }
      {
        assertion = cfg.email -> cfg.enable;
        message = "Email client requires productivity feature to be enabled";
      }
      {
        assertion = cfg.calendar -> cfg.enable;
        message = "Calendar requires productivity feature to be enabled";
      }
    ];
  };
}
