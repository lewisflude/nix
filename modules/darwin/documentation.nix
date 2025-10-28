{
  lib,
  config,
  ...
}: let
  cfg = config.host.features.documentation;
in {
  options.host.features.documentation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable documentation for system packages";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable all documentation types
    documentation = {
      enable = true; # Master switch for documentation
      doc.enable = true; # Enable documentation distributed in packages' /share/doc
      info.enable = true; # Enable GNU info pages and info command
      man.enable = true; # Enable man pages and man command
    };

    # Set the nix-darwin configuration path
    environment.darwinConfig = "$HOME/.config/nix";
  };
}
