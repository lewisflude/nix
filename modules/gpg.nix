# GPG and YubiKey configuration - ALL config classes in ONE file
# Dendritic pattern: One feature = one file spanning all configurations
{ config, ... }:
{
  # ═══════════════════════════════════════════════════════════════════
  # NixOS system-level GPG/YubiKey configuration
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.nixos.gpg =
    { pkgs, ... }:
    {
      services.pcscd.enable = true;
      services.udev.packages = [ pkgs.yubikey-personalization ];
      environment.systemPackages = [
        pkgs.gnupg
        pkgs.yubikey-personalization
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
        pkgs.yubikey-personalization
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
      isDarwin = pkgs.stdenv.isDarwin;
      gtkThemeName = config.theming.signal.gtk.themeName or null;
      pinCacheTtl = {
        gpg = {
          default = 3600; # 1 hour - PIN stays cached after last use
          max = 43200; # 12 hours - forces re-entry after absolute time
        };
        ssh = 3600;
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
        maxCacheTtlSsh = pinCacheTtl.ssh;
        grabKeyboardAndMouse = true;
        noAllowExternalCache = true;
        extraConfig = "allow-preset-passphrase\nallow-loopback-pinentry";
      };
    };
}
