{ pkgs, ... }:
{
  # ==========================================================================
  # DISABLED: DMS Power Management and Lock Screen
  # ==========================================================================
  # DMS now handles:
  # - Idle timeouts and auto-lock (settings.powerManagement)
  # - Lock screen with media controls (settings.lockScreen)
  # - Fullscreen inhibit for gaming/streaming (inhibitOnFullscreen)
  #
  # See: home/nixos/dank-material-shell.nix
  # ==========================================================================

  # swayidle disabled - DMS handles idle management
  services.swayidle.enable = false;

  # swaylock disabled - DMS has integrated lock screen
  programs.swaylock.enable = false;

  # streaming-mode helper removed - DMS inhibitOnFullscreen replaces it
  # If manual inhibit control is needed, use: dms power inhibit on/off
}
