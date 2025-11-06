{
  config,
  lib,
  ...
}:
{

  config = lib.mkIf config.host.features.development.java {
    programs.java.enable = true;
  };
}
