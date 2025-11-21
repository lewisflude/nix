{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.media.audio;

  # Script to reset and reconfigure the Apogee Symphony Desktop
  resetApogeeScript = pkgs.writeShellScript "reset-apogee" ''
    set -euo pipefail

    # Log to systemd journal
    log() {
      echo "$@" | ${pkgs.systemd}/bin/systemd-cat -t apogee-reset -p info
    }

    log "Apogee Symphony Desktop detected, resetting device state..."

    # Wait for device to be fully enumerated
    sleep 2

    # Find the USB device bus and device numbers
    DEVICE_INFO=$(${pkgs.usbutils}/bin/lsusb | ${pkgs.gnugrep}/bin/grep -i "Apogee Electronics Corp" | head -n1)
    if [ -z "$DEVICE_INFO" ]; then
      log "ERROR: Apogee device not found in lsusb output"
      exit 1
    fi

    BUS=$(echo "$DEVICE_INFO" | ${pkgs.gawk}/bin/awk '{print $2}')
    DEVICE=$(echo "$DEVICE_INFO" | ${pkgs.gawk}/bin/awk '{print $4}' | ${pkgs.gnused}/bin/sed 's/://')

    log "Found Apogee on Bus $BUS Device $DEVICE"

    # Reset the USB device to clear any macOS/Ableton state
    USB_PATH="/dev/bus/usb/$BUS/$DEVICE"
    if [ -e "$USB_PATH" ]; then
      log "Resetting USB device at $USB_PATH"
      ${pkgs.usb-reset}/bin/usbreset "$USB_PATH" || log "WARNING: USB reset failed, continuing anyway"
    else
      log "WARNING: USB device path $USB_PATH not found"
    fi

    # Wait for device to reinitialize
    sleep 3

    # Restart PipeWire services for the user running the audio session
    # Find the user with an active PipeWire session
    AUDIO_USER=$(${pkgs.systemd}/bin/loginctl list-users --no-legend | ${pkgs.gawk}/bin/awk '{print $2}' | head -n1)

    if [ -n "$AUDIO_USER" ]; then
      log "Restarting PipeWire services for user: $AUDIO_USER"

      # Get the user's UID for systemctl --user
      USER_ID=$(${pkgs.coreutils}/bin/id -u "$AUDIO_USER")

      # Restart PipeWire services
      ${pkgs.systemd}/bin/systemctl --machine="$AUDIO_USER@.host" --user restart pipewire.service || log "WARNING: Failed to restart pipewire"
      ${pkgs.systemd}/bin/systemctl --machine="$AUDIO_USER@.host" --user restart pipewire-pulse.service || log "WARNING: Failed to restart pipewire-pulse"
      ${pkgs.systemd}/bin/systemctl --machine="$AUDIO_USER@.host" --user restart wireplumber.service || log "WARNING: Failed to restart wireplumber"

      # Wait for services to stabilize
      sleep 2

      # Restart the custom audio routing service if it exists
      ${pkgs.systemd}/bin/systemctl --machine="$AUDIO_USER@.host" --user restart setup-audio-routing.service || log "INFO: setup-audio-routing.service not found or failed to restart"

      log "Apogee Symphony Desktop reset complete"
    else
      log "WARNING: No logged-in user found, skipping PipeWire restart"
    fi
  '';
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Install usb-reset utility
    environment.systemPackages = [ pkgs.usb-reset ];

    # Udev rule to trigger reset when Apogee is connected
    # This catches the device when switching from macOS via KVM
    services.udev.extraRules = ''
      # Apogee Symphony Desktop - Auto-reset when connected via KVM switch
      # Vendor ID: 0c60 (Apogee Electronics Corp)
      # Product ID: 0014 (Symphony Desktop)
      # Trigger: Device add/change events to catch KVM switches
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="0c60", ATTR{idProduct}=="0014", \
        TAG+="systemd", ENV{SYSTEMD_WANTS}="apogee-reset@$env{BUSNUM}-$env{DEVNUM}.service"
    '';

    # Systemd service template for the reset script
    # Uses a template so multiple instances can run if needed
    systemd.services."apogee-reset@" = {
      description = "Reset Apogee Symphony Desktop audio interface";
      after = [ "sound.target" ];

      # Allow service to fail without marking system as degraded
      # Sometimes USB reset might fail if device is in use
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${resetApogeeScript}";
        RemainAfterExit = false;
        # Run with elevated privileges to access USB devices
        User = "root";
        # Don't restart on failure - this is a one-time operation
        Restart = "no";
        # Timeout after 30 seconds if something goes wrong
        TimeoutStartSec = "30s";
      };
    };

    # Optional: Add a manual command users can run if needed
    # Usage: sudo apogee-reset
    environment.shellAliases = {
      apogee-reset = "sudo ${resetApogeeScript}";
    };
  };
}
