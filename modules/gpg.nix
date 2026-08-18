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
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
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
        # Replaced by the deferred version below. home-manager's integration
        # runs gpg-connect-agent synchronously in every interactive shell, which
        # is both a fork+IPC per shell and console I/O during powerlevel10k's
        # instant prompt window. SSH_AUTH_SOCK is unaffected: that is emitted by
        # enableSshSupport, not by this option.
        enableZshIntegration = false;
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

      # Deferred replacement for services.gpg-agent.enableZshIntegration.
      # GPG_TTY is set synchronously (pinentry needs it, and it costs nothing);
      # only the agent round-trip is deferred until after the prompt is up.
      programs.zsh.initContent = lib.mkAfter ''
        export GPG_TTY=$TTY
        if (( ''${+functions[zsh-defer]} )); then
          zsh-defer -c '${pkgs.gnupg}/bin/gpg-connect-agent --quiet updatestartuptty /bye >/dev/null'
        else
          ${pkgs.gnupg}/bin/gpg-connect-agent --quiet updatestartuptty /bye >/dev/null
        fi
      '';
    };
}
