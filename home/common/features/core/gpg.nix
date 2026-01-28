{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem system;
  isDarwin = lib.hasSuffix "-darwin" system;

  # PIN and Touch Cache Configuration
  #
  # IMPORTANT: YubiKey has TWO separate cache mechanisms:
  #
  # 1. TOUCH POLICY (configured on YubiKey via ykman):
  #    - "Cached" (15s): Touch once, valid for 15 seconds
  #    - "On": Touch required for every operation
  #    - "Off": No touch required (less secure)
  #    Current setting visible via: ykman openpgp info
  #
  # 2. PIN CACHE (configured here via gpg-agent):
  #    - Controls how long PIN stays cached after first entry
  #    - NOTE: With smart cards, PIN is often cached at card-level until unplugged
  #    - These settings provide an upper bound, but may not behave exactly as specified
  #
  # Expected behavior with "Cached" touch policy + 1h PIN cache:
  # - First operation: Enter PIN + touch YubiKey
  # - Within 15 seconds: No PIN, no touch (both cached)
  # - After 15s, within 1h: No PIN, touch required
  # - After 1 hour: Enter PIN again + touch
  #
  # Standard practice: 1 hour for both GPG and SSH
  pinCacheTtl = {
    gpg = 3600;      # 1 hour for GPG operations (commit signing, etc.)
    ssh = 3600;      # 1 hour for SSH operations (standard security practice)
  };
in
{
  home.packages = [
    # Note: gnupg is automatically installed by programs.gpg.enable = true
    # pinentry packages are referenced by the wrapper script below, not needed in home.packages
    pkgs.yubikey-manager  # ykman CLI tool for YubiKey configuration
  ]
  ++ (
    if isDarwin then
      [
        # macOS: pinentry_mac (native macOS GUI)
        pkgs.pinentry_mac

        # macOS: YubiKey touch notifications (OPTIONAL)
        # Uncomment to add visual feedback when YubiKey needs to be touched
        # Alternative to yubikey-touch-detector (Linux only)
        #
        # (pkgs.buildGoModule rec {
        #   pname = "yknotify";
        #   version = "1.0.0";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "noperator";
        #     repo = "yknotify";
        #     rev = "v${version}";
        #     sha256 = lib.fakeSha256;  # Replace with actual hash after first build attempt
        #   };
        #   vendorHash = null;
        # })
      ]
    else
      [
        # Linux: pinentry packages are used by the auto-detection wrapper
        # They are referenced directly in the wrapper script, not installed separately
        # Linux: YubiKey touch detector configured at system level
        # (see modules/nixos/hardware/yubikey.nix)
      ]
  );

  # Note: YubiKey touch detector configuration:
  # - Linux: Configured at system level via programs.yubikey-touch-detector.enable
  #          (see modules/nixos/hardware/yubikey.nix)
  # - macOS: yknotify can be installed (see commented code above) or manually:
  #          go install github.com/noperator/yknotify@latest
  #          Run: yknotify (provides visual notifications when touch needed)
  #          See: https://github.com/noperator/yknotify

  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      # Disable CCID to use pcscd (required for GnuPG 2.4+)
      # Per Arch Wiki: https://wiki.archlinux.org/title/GnuPG#GnuPG_with_pcscd_(PCSC_Lite)
      # Without this, scdaemon tries direct CCID access which conflicts with pcscd
      # Note: pcscd service is enabled at system level via modules/nixos/features/security.nix
      disable-ccid = true;

      # REMOVED: card-timeout = "5"
      # Reason: Aggressive timeout can kill card sessions and force PIN re-entry
      # Let scdaemon manage card presence naturally for better PIN caching
    }
    // (
      if isDarwin then
        {
          # macOS: Use pcsc-shared to allow PIN caching while sharing
          # the reader with macOS's built-in PC/SC daemon (com.apple.ctkpcscd)
          pcsc-shared = true;

          # macOS: Disable PIV application to prevent conflicts with OpenPGP
          # YubiKeys support both PIV and OpenPGP applications simultaneously
          # Disabling PIV prevents card resets that break PIN caching
          # Only disable PIV if you're not using it for other purposes
          disable-application = "piv";
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

      # Modern best practices
      fixed-list-mode = true;           # Display full timestamps
      no-comments = true;               # Cleaner ASCII armor output
      list-options = "show-uid-validity";    # Show key validity when listing
      verify-options = "show-uid-validity";  # Show key validity when verifying
      keyserver = "hkps://keys.openpgp.org"; # Use secure keyserver pool
    };
  };

  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;        # Explicit smartcard/YubiKey support
    enableSshSupport = true;
    enableZshIntegration = false; # Disabled: we add deferred version manually for faster startup
    enableExtraSocket = true;     # Useful for GPG agent forwarding

    # Declarative SSH key configuration (YubiKey authentication keys)
    # List fingerprints of all YubiKey OpenPGP authentication subkeys
    # To get fingerprint: gpg --list-secret-keys --keyid-format=long
    sshKeys = [
      "495B10388160753867D2B6F7CAED2ED08F4D4323"  # YubiKey 1 - OpenPGP auth subkey
      # "ANOTHER_FINGERPRINT_HERE"                 # YubiKey 2 (backup) - uncomment and add if different
    ];

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

    # PIN cache timeouts: Balance security with usability
    # Configure values in the 'pinCacheTtl' let binding at the top of this file
    # To apply changes: gpgconf --reload gpg-agent
    defaultCacheTtl = pinCacheTtl.gpg;
    maxCacheTtl = pinCacheTtl.gpg;
    defaultCacheTtlSsh = pinCacheTtl.ssh;
    maxCacheTtlSsh = pinCacheTtl.ssh;

    grabKeyboardAndMouse = true;   # Tell the pinentry to grab keyboard and mouse
    noAllowExternalCache = true;   # Prevent external passphrase caching for security

    # Additional agent configuration options
    extraConfig = ''
      allow-preset-passphrase
      allow-loopback-pinentry
    '';
    # Reload config: gpgconf --reload gpg-agent
    # Reset card: gpgconf --kill scdaemon
  };

  # Critical: Export GPG_TTY and SSH_AUTH_SOCK for proper operation
  # Since enableZshIntegration is false, we must handle this manually
  #
  # macOS Note: System runs its own ssh-agent by default
  # Our SSH_AUTH_SOCK export overrides it to use gpg-agent instead
  # Verify with: echo $SSH_AUTH_SOCK (should show gpg-agent socket path)
  # If conflicts occur, disable system ssh-agent with:
  #   launchctl disable user/$UID/com.openssh.ssh-agent
  programs.zsh.initContent = ''
    export GPG_TTY=$(tty)
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';

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
  #    This is handled by programs.zsh.initExtra above
  #
  # Reference: https://github.com/ghostty-org/ghostty/discussions/5951
}
