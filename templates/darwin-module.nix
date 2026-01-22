{
  pkgs,
  username,
  ...
}:
{
  system.defaults = {
    dock.autohide = true;
    finder.FXPreferredViewStyle = "clmv";
  };
  environment.systemPackages = [
    pkgs.terminal-notifier
    pkgs.reattach-to-user-namespace
  ];
  homebrew = {
    enable = true;
    brews = [
      "example-brew-package"
    ];
    casks = [
      "example-cask-application"
    ];
  };
  services.example-darwin = {
    enable = true;
  };
  launchd.daemons.example = {
    serviceConfig = {
      ProgramArguments = [
        "/path/to/program"
        "--user"
        username
      ];
      RunAtLoad = true;
    };
  };
}
