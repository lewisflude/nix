{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.media.audio;

  # Script to reset and reconfigure the Apogee Symphony Desktop after KVM switching
  resetApogeeScript = pkgs.writeShellScript "reset-apogee" ''
    set -euo pipefail

    # Log to systemd journal
    log() {
      echo "$@" | ${pkgs.systemd}/bin/systemd-cat -t apogee-reset -p info
    }

    log "Apogee Symphony Desktop detected after KVM switch, resetting device..."

    # Wait for device to be fully enumerated by kernel
    sleep 2

    # Find the USB device bus and device numbers
    DEVICE_INFO=$(${pkgs.usbutils}/bin/lsusb | ${pkgs.gnugrep}/bin/grep "0c60:002a" | head -n1)
    if [ -z "$DEVICE_INFO" ]; then
      log "ERROR: Apogee Symphony Desktop (0c60:002a) not found"
      exit 1
    fi

    BUS=$(echo "$DEVICE_INFO" | ${pkgs.gawk}/bin/awk '{print $2}')
    DEVICE=$(echo "$DEVICE_INFO" | ${pkgs.gawk}/bin/awk '{print $4}' | ${pkgs.gnused}/bin/sed 's/://')

    log "Found Apogee Symphony Desktop on Bus $BUS Device $DEVICE"

    # Reset the USB device to clear any state from previous system (e.g., macOS)
    USB_PATH="/dev/bus/usb/$BUS/$DEVICE"
    if [ -e "$USB_PATH" ]; then
      log "Resetting USB device at $USB_PATH"
      ${pkgs.usb-reset}/bin/usbreset "$USB_PATH" 2>&1 | ${pkgs.systemd}/bin/systemd-cat -t apogee-reset || \
        log "WARNING: USB reset failed (device may be in use), continuing..."
    else
      log "WARNING: USB device path $USB_PATH not found"
    fi

    # Wait for device to reinitialize
    sleep 2

    # Restart PipeWire services for the logged-in user
    # Find the first logged-in user (excluding root and system users)
    AUDIO_USER=$(${pkgs.systemd}/bin/loginctl list-users --no-legend | \
      ${pkgs.gawk}/bin/awk '{print $2}' | \
      ${pkgs.gnugrep}/bin/grep -v "^root$" | \
      head -n1)

    if [ -n "$AUDIO_USER" ]; then
      log "Restarting PipeWire services for user: $AUDIO_USER"

      # Restart PipeWire services using systemctl --machine
      ${pkgs.systemd}/bin/systemctl --machine="$AUDIO_USER@.host" --user restart pipewire.service 2>&1 | \
        ${pkgs.systemd}/bin/systemd-cat -t apogee-reset || log "WARNING: Failed to restart pipewire"

      ${pkgs.systemd}/bin/systemctl --machine="$AUDIO_USER@.host" --user restart wireplumber.service 2>&1 | \
        ${pkgs.systemd}/bin/systemd-cat -t apogee-reset || log "WARNING: Failed to restart wireplumber"

      ${pkgs.systemd}/bin/systemctl --machine="$AUDIO_USER@.host" --user restart pipewire-pulse.service 2>&1 | \
        ${pkgs.systemd}/bin/systemd-cat -t apogee-reset || log "WARNING: Failed to restart pipewire-pulse"

      # Wait for services to stabilize
      sleep 1

      # Restart the Apogee speakers loopback service if it exists
      ${pkgs.systemd}/bin/systemctl --machine="$AUDIO_USER@.host" --user restart apogee-speakers-loopback.service 2>&1 | \
        ${pkgs.systemd}/bin/systemd-cat -t apogee-reset || log "INFO: apogee-speakers-loopback not running or failed to restart"

      log "Apogee Symphony Desktop reset complete - device ready"
    else
      log "WARNING: No logged-in user found, skipping PipeWire restart"
      log "You may need to manually run: systemctl --user restart pipewire wireplumber"
    fi
  '';
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Install usb-reset utility for KVM switching
    environment.systemPackages = [ pkgs.usb-reset ];

    # Disable USB autosuspend for Apogee Symphony Desktop
    # Audio interfaces should never be power-managed to avoid dropouts and connection issues
    # Vendor ID: 0c60 (Apogee Electronics Corp), Product ID: 002a (Symphony Desktop)
    #
    # Also trigger automatic reset when device is reconnected (e.g., via KVM switch)
    services.udev.extraRules = ''
      # Disable USB autosuspend
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0c60", ATTR{idProduct}=="002a", \
        TEST=="power/control", ATTR{power/control}="on"

      # Trigger automatic reset when Apogee is connected via KVM switch
      # This clears any state from the previous system and restarts PipeWire
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0c60", ATTR{idProduct}=="002a", \
        TAG+="systemd", ENV{SYSTEMD_WANTS}="apogee-kvm-reset@$env{BUSNUM}-$env{DEVNUM}.service"
    '';

    # Systemd service to automatically reset Apogee after KVM switching
    systemd.services."apogee-kvm-reset@" = {
      description = "Reset Apogee Symphony Desktop after KVM switch";
      after = [ "sound.target" ];
      # Use template so multiple instances can run if device reconnects rapidly
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${resetApogeeScript}";
        RemainAfterExit = false;
        User = "root";
        Restart = "no";
        TimeoutStartSec = "30s";
      };
    };

    # Provide manual reset command in case automatic reset fails
    # Usage: sudo apogee-reset
    environment.shellAliases = {
      apogee-reset = "sudo ${resetApogeeScript}";
    };
  };
}
