{
  config,
  lib,
  ...
}: {
  # Java is controlled by host.features.development.java flag
  # Add 'java = true;' to development features in host config to enable
  config = lib.mkIf (config.host.features.development.java or false) {
    programs.java.enable = true;
  };
}
