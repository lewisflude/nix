# Template for modules/darwin/ - Darwin/macOS-specific system modules
{
  pkgs,
  username,
  ...
}:
{
  # Darwin-specific system configuration
  # No platform detection needed - this module only loads on Darwin
  
  # macOS system settings
  system.defaults = {
    dock.autohide = true;
    finder.FXPreferredViewStyle = "clmv";
  };

  # macOS-specific packages
  environment.systemPackages = with pkgs; [
    # macOS-specific or preferred packages
    terminal-notifier
    reattach-to-user-namespace
  ];

  # Homebrew configuration (Darwin only)
  homebrew = {
    enable = true;
    brews = [
      "example-brew-package"
    ];
    casks = [
      "example-cask-application"
    ];
  };

  # Darwin-specific services
  services.example-darwin = {
    enable = true;
    # Darwin-specific service configuration
  };

  # LaunchDaemons (Darwin equivalent of systemd)
  launchd.daemons.example = {
    serviceConfig = {
      ProgramArguments = [ "/path/to/program" ];
      RunAtLoad = true;
    };
  };
}