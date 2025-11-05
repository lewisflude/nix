# Productivity feature module (cross-platform)
# Controlled by host.features.productivity.*
# Provides office tools, note-taking, email, calendar, and resume management
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.host.features.productivity;
in {
  config = mkIf cfg.enable {
    # System-level packages (NixOS only)
    # Note: Most productivity tools are user-level and installed via home-manager
    # This module coordinates system-level settings if needed

    # Assertions
    assertions = [
      {
        assertion = cfg.resume -> cfg.enable;
        message = "Resume generation requires productivity feature to be enabled";
      }
    ];
  };
}
