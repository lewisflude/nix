# Documentation configuration for NixOS
# Controlled by host.features.documentation
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
    # Enable all documentation types
    # Note: NixOS enables documentation by default, but we allow explicit control
    documentation = {
      enable = true; # Master switch for documentation
      doc.enable = true; # Enable documentation distributed in packages' /share/doc (includes python3.12-doc)
      info.enable = true; # Enable GNU info pages and info command
      man.enable = true; # Enable man pages and man command
    };
  };
}
