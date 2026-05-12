# GPG and YubiKey configuration - ALL config classes in ONE file
# Dendritic pattern: One feature = one file spanning all configurations
#
# This module provides:
# - NixOS: PC/SC daemon, udev rules, GPG smartcard support, touch detector
# - Darwin: GPG packages
# - Home-Manager: GPG agent, signing config, YubiKey tools
{ config, ... }:
{
  # ═══════════════════════════════════════════════════════════════════
  # NixOS system-level GPG/YubiKey configuration
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.nixos.gpg =
    { pkgs, ... }:
    {
      # PC/SC daemon for smartcard communication (required for YubiKey)
      services.pcscd.enable = true;

      # udev rules for YubiKey device access
      services.udev.packages = [
        pkgs.libfido2 # Modern FIDO2/U2F support for YubiKey 5 series
      ];

      # Enable GPG smartcard support
      hardware.gpgSmartcards.enable = true;

      # YubiKey touch detector: Visual notifications when YubiKey needs touch
      programs.yubikey-touch-detector = {
        enable = true;
        libnotify = true;
      };

    };

  # ═══════════════════════════════════════════════════════════════════
  # Home-manager GPG configuration (works on NixOS AND Darwin)
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.homeManager.gpg =
    hmArgs@{
      pkgs,
      lib,
      ...
    }:
    let
      hmConfig = hmArgs.config;
      inherit (pkgs.stdenv) isDarwin;
      gtkThemeName = hmConfig.theming.signal.gtk.themeName or null;
    in
    {
      home.packages = [
        pkgs.yubikey-manager
      ]
      ++ lib.optionals isDarwin [
        pkgs.pinentry_mac
        pkgs.terminal-notifier
      ];

      programs.gpg = {
        enable = true;
        scdaemonSettings = {
          disable-ccid = true;
          pcsc-shared = true; # Allow other apps to access YubiKey while GPG is running
        }
        // lib.optionalAttrs isDarwin {
          disable-application = "piv";
        };
        settings = {
          keyid-format = "0xlong";
          with-fingerprint = true;
          personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";
          cert-digest-algo = "SHA512";
          default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
          personal-cipher-preferences = "AES256 AES192 AES";
          fixed-list-mode = true;
          no-comments = true;
          keyserver = "hkps://keys.openpgp.org";
          no-emit-version = true;
          s2k-digest-algo = "SHA512";
          s2k-cipher-algo = "AES256";
          personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
          throw-keyids = true;
        };
      };

      services.gpg-agent = {
        enable = true;
        enableScDaemon = true;
        enableSshSupport = true;
        enableZshIntegration = true;
        enableExtraSocket = true;
        sshKeys = [ config.constants.gpg.sshAuthKey ];
        pinentry.package =
          if isDarwin then
            pkgs.pinentry_mac
          else
            pkgs.writeShellScriptBin "pinentry-auto" ''
              if [ -n "$SSH_CONNECTION" ] || [ -z "$DISPLAY" ]; then
                exec ${pkgs.pinentry-tty}/bin/pinentry-tty "$@"
              else
                ${lib.optionalString (gtkThemeName != null) "export GTK_THEME=\"${gtkThemeName}\""}
                exec ${pkgs.pinentry-gnome3}/bin/pinentry-gnome3 "$@"
              fi
            '';
        defaultCacheTtl = 60; # 1 minute idle timeout (drduh recommendation)
        maxCacheTtl = 120; # 2 minutes max (drduh recommendation)
        defaultCacheTtlSsh = 60;
        maxCacheTtlSsh = 120;
        grabKeyboardAndMouse = !isDarwin; # GTK pinentry only
        noAllowExternalCache = true;
        extraConfig = "allow-loopback-pinentry";
      };
    };
}
