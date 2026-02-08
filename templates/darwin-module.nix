# Darwin-only Module Template - Dendritic Pattern
# For features that only apply to macOS systems
{ config, lib, ... }:
let
  inherit (config) username;
  constants = config.constants;
in
{
  flake.modules.darwin.FEATURE_NAME =
    { pkgs, lib, ... }:
    {
      # System packages (available to all users)
      environment.systemPackages = [
        pkgs.terminal-notifier
        pkgs.reattach-to-user-namespace
      ];

      # Homebrew configuration
      homebrew = {
        enable = true;
        brews = [
          "example-brew-package"
        ];
        casks = [
          "example-cask-application"
        ];
      };

      # System defaults (macOS preferences)
      system.defaults = {
        dock.autohide = true;
        finder.FXPreferredViewStyle = "clmv";
      };

      # launchd services (macOS equivalent of systemd)
      launchd.daemons.example = {
        serviceConfig = {
          ProgramArguments = [ "${pkgs.example}/bin/example" ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };
}
