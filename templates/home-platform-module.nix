{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    platform-specific-tool
    platform-specific-app
  ];
  programs.example = {
    enable = true;
    settings = {
      platform = "current-platform";
      integration = "platform-specific-service";
    };
  };
  services.example = {
    enable = true;
  };
  home.file.".platform-config" = {
    text = ''
      platform_setting=value
      home_directory=${config.home.homeDirectory}
    '';
  };
  imports = [
    ./other-platform-module.nix
  ];
}
