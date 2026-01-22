{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.security;
in
{
  config = mkMerge [
    (mkIf cfg.enable {
      services.pcscd.enable = mkIf cfg.yubikey true;
    })

    {
      assertions = [
        {
          assertion = cfg.yubikey -> cfg.enable;
          message = "YubiKey support requires security feature to be enabled";
        }
        {
          assertion = cfg.gpg -> cfg.enable;
          message = "GPG support requires security feature to be enabled";
        }
      ];
    }
  ];
}
