{
  lib,
  config,
  ...
}:
let
  cfg = config.host.features.documentation;
in
{
  options.host.features.documentation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable documentation for system packages";
    };
  };

  config = lib.mkIf cfg.enable {

    documentation = {
      enable = true;
      doc.enable = true;
      info.enable = true;
      man.enable = true;
    };
  };
}
