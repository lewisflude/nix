# Template for home/darwin/ or home/nixos/ - Platform-specific Home Manager modules
{ pkgs
, config
, ...
}: {
  # Platform-specific Home Manager configuration
  # No platform detection needed - this module only loads on the target platform

  # Platform-specific user packages
  home.packages = with pkgs; [
    # Platform-specific packages only
    platform-specific-tool
    platform-specific-app
  ];

  # Platform-specific program configuration
  programs.example = {
    enable = true;

    # All settings here are platform-specific
    settings = {
      platform = "current-platform";
      integration = "platform-specific-service";
    };
  };

  # Platform-specific services
  services.example = {
    enable = true;
    # Platform-specific service configuration
  };

  # Platform-specific file configuration using config parameter
  home.file.".platform-config" = {
    text = ''
      # Platform-specific configuration
      platform_setting=value
      home_directory=${config.home.homeDirectory}
    '';
  };

  # Example file configurations using config parameter:
  # For Darwin: Use absolute paths or config.home.homeDirectory
  # home.file."${config.home.homeDirectory}/Library/Application Support/Example/config" = { ... };

  # For NixOS: Use XDG directories or config.home.homeDirectory
  # home.file."${config.home.homeDirectory}/.config/example/config" = { ... };

  # Example of importing other platform-specific modules
  imports = [
    # Other platform-specific modules in this directory
    ./other-platform-module.nix
  ];
}
