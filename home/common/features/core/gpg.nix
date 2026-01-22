{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem system;
  isDarwin = lib.hasSuffix "-darwin" system;
in
{
  home.packages = [
    # Note: gnupg is automatically installed by programs.gpg.enable = true
    # pinentry packages are referenced by the wrapper script below, not needed in home.packages
  ]
  ++ (
    if isDarwin then
      [
        # macOS: pinentry_mac (native macOS GUI)
        pkgs.pinentry_mac
      ]
    else
      [
        # Linux: pinentry packages are used by the auto-detection wrapper
        # They are referenced directly in the wrapper script, not installed separately
      ]
  );

  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      # Cache the Yubikey PIN for 24 hours
      card-timeout = "86400";

      # Disable CCID to use pcscd (required for GnuPG 2.4+)
      # Per Arch Wiki: https://wiki.archlinux.org/title/GnuPG#GnuPG_with_pcscd_(PCSC_Lite)
      # Without this, scdaemon tries direct CCID access which conflicts with pcscd
      disable-ccid = true;
    }
    // (
      if isDarwin then
        {
          # macOS: Use pcsc-shared to allow PIN caching while sharing
          # the reader with macOS's built-in PC/SC daemon (com.apple.ctkpcscd)
          pcsc-shared = true;
        }
      else
        { }
    );

    # GPG program settings for better security and usability
    # Per Arch Wiki: https://wiki.archlinux.org/title/GnuPG#Tips_and_tricks
    settings = {
      # Always show long key IDs (not short 8-char IDs which can collide)
      keyid-format = "0xlong";

      # Always show full fingerprints
      with-fingerprint = true;

      # Stronger digest algorithms (Arch Wiki "Different algorithm" section)
      personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";
      cert-digest-algo = "SHA512";
      default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

      # Use strongest ciphers
      personal-cipher-preferences = "AES256 AES192 AES";
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableZshIntegration = false; # Disabled: we add deferred version manually for faster startup
    pinentry.package =
      # Auto-detecting pinentry wrapper:
      # - Uses terminal pinentry (tty) for SSH sessions or headless environments
      # - Uses GUI pinentry (GNOME/macOS) for graphical desktop sessions
      # This ensures proper pinentry selection without manual intervention
      if isDarwin then
        pkgs.pinentry_mac
      else
        pkgs.writeShellScriptBin "pinentry-auto" ''
          # Detect SSH session or missing display
          if [ -n "$SSH_CONNECTION" ] || [ -z "$DISPLAY" ]; then
            exec ${pkgs.pinentry-tty}/bin/pinentry-tty "$@"
          else
            exec ${pkgs.pinentry-gnome3}/bin/pinentry-gnome3 "$@"
          fi
        '';

    # Cache GPG and SSH keys for 24 hours
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    defaultCacheTtlSsh = 86400;
    maxCacheTtlSsh = 86400;

    extraConfig = ''
      allow-preset-passphrase
      grab
      allow-loopback-pinentry
    '';
  };

  # === Ghostty Terminal Compatibility Notes ===
  # If you encounter "not a tty" or "Screen or window too small" errors in Ghostty:
  #
  # 1. Ensure terminfo is properly configured:
  #    Ghostty sets TERM=xterm-ghostty automatically when terminfo is available
  #    See: https://ghostty.org/docs/help/terminfo
  #
  # 2. Restart gpg-agent from within Ghostty:
  #    $ gpgconf --kill gpg-agent
  #    Or: $ killall gpg-agent
  #    The agent will restart automatically on next use
  #
  # 3. For commit signing, ensure GPG_TTY is set:
  #    This is typically handled by shell integration automatically
  #
  # Reference: https://github.com/ghostty-org/ghostty/discussions/5951

  # SSH control file for GPG agent
  # Manage SSH keys that can be used via gpg-agent
  # This lists YubiKey authentication keys that should be available for SSH
  home.file.".gnupg/sshcontrol".text = ''
    # List of allowed ssh keys.  Only keys present in this file are used
    # in the SSH protocol.  The ssh-add tool may add new entries to this
    # file to enable them; you may also add them manually.  Comment
    # lines, like this one, as well as empty lines are ignored.  Lines do
    # have a certain length limit but this is not serious limitation as
    # the format of the entries is fixed and checked by gpg-agent. A
    # non-comment line starts with optional white spaces, followed by the
    # keygrip of the key given as 40 hex digits, optionally followed by a
    # caching TTL in seconds, and another optional field for arbitrary
    # flags.   Prepend the keygrip with an '!' mark to disable it.

    # YubiKey OpenPGP Authentication key (RSA 4096)
    # Added: 2025-01-20
    # This is the GPG authentication subkey stored on YubiKey
    # SHA256:RK1I2SGm1fOLgNpXWHrQD1xyqmLorayXhjqDzIbLlO8
    495B10388160753867D2B6F7CAED2ED08F4D4323
  '';
}
