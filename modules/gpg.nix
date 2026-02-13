# GPG and YubiKey configuration - ALL config classes in ONE file
# Dendritic pattern: One feature = one file spanning all configurations
#
# This module provides:
# - NixOS: PC/SC daemon, udev rules, GPG smartcard support, touch detector
# - Darwin: GPG packages
# - Home-Manager: GPG agent, signing config, YubiKey tools
_: {
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

      # Lock screen when YubiKey is physically removed (vendor 1050 = Yubico)
      services.udev.extraRules = ''
        ACTION=="remove", ENV{ID_VENDOR_ID}=="1050", RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
      '';

      # Enable GPG smartcard support
      hardware.gpgSmartcards.enable = true;

      # YubiKey touch detector: Visual notifications when YubiKey needs touch
      programs.yubikey-touch-detector = {
        enable = true;
        libnotify = true;
      };

      environment.systemPackages = [
        pkgs.gnupg
      ];
    };

  # ═══════════════════════════════════════════════════════════════════
  # Darwin system-level GPG/YubiKey configuration
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.darwin.gpg =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.gnupg
      ];
    };

  # ═══════════════════════════════════════════════════════════════════
  # Home-manager GPG configuration (works on NixOS AND Darwin)
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.homeManager.gpg =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv) isDarwin;
      gtkThemeName = config.theming.signal.gtk.themeName or null;
      # Cache TTLs following drduh/YubiKey-Guide recommendations
      # Note: These primarily affect non-smartcard operations; YubiKey PIN
      # is cached by hardware until removal (these don't override that)
      pinCacheTtl = {
        gpg = {
          default = 60; # 1 minute idle timeout (drduh recommendation)
          max = 120; # 2 minutes max (drduh recommendation)
        };
        ssh = 60; # 1 minute for SSH keys
      };
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
        enableZshIntegration = false;
        enableExtraSocket = true;
        sshKeys = [ "495B10388160753867D2B6F7CAED2ED08F4D4323" ];
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
        defaultCacheTtl = pinCacheTtl.gpg.default;
        maxCacheTtl = pinCacheTtl.gpg.max;
        defaultCacheTtlSsh = pinCacheTtl.ssh;
        maxCacheTtlSsh = pinCacheTtl.gpg.max; # Use same max as GPG
        grabKeyboardAndMouse = true;
        noAllowExternalCache = true;
        extraConfig = "allow-preset-passphrase\nallow-loopback-pinentry";
      };
    };
}
