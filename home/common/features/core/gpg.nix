{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem system;
  isDarwin = lib.hasSuffix "-darwin" system;

  # YubiKey touch notification tool for macOS
  # Provides visual dock icon + desktop notifications when YubiKey touch is required
  yknotify = pkgs.buildGoModule rec {
    pname = "yknotify";
    version = "unstable-2025-01-20";

    src = pkgs.fetchFromGitHub {
      owner = "noperator";
      repo = "yknotify";
      rev = "999f01cc0d64e3f4c241b157d697d6ef22374e84";
      hash = "sha256-SHedRv7WGaGmZOP5pt3/TFc5hF/Y8bJyib2ib+nfa4M=";
    };

    vendorHash = null;  # No external dependencies

    meta = with lib; {
      description = "Displays a notification when a YubiKey is waiting for touch";
      homepage = "https://github.com/noperator/yknotify";
      license = licenses.mit;
      platforms = platforms.darwin;  # macOS only
    };
  };

  # Wrapper script that pipes yknotify output to terminal-notifier
  # Based on: https://github.com/noperator/yknotify/blob/main/yknotify.sh
  yknotifyWrapper = pkgs.writeShellScriptBin "yknotify-wrapper" ''
    # 2-second delay between notifications to avoid spam
    LAST_NTFY=0

    while IFS= read -r line; do
      # Log output for debugging
      echo "$line"

      # Extract notification type from JSON
      message="$(echo "$line" | ${pkgs.jq}/bin/jq -r '.type // empty')"

      # Filter: Only process GPG events, ignore FIDO2 (browser WebAuthn polling)
      if [ "$message" != "GPG" ]; then
        continue
      fi

      # Rate limit: 2-second delay between notifications
      NOW="$(${pkgs.coreutils}/bin/date +%s)"
      if [[ "$NOW" -le "$((LAST_NTFY + 2))" ]]; then
        continue
      fi
      LAST_NTFY="$NOW"

      if [ -n "$message" ]; then
        # Send notification with sound
        ${pkgs.terminal-notifier}/bin/terminal-notifier \
          -title "yknotify" \
          -message "$message" \
          -sound Submarine
      fi
    done < <(${yknotify}/bin/yknotify)
  '';

  pinCacheTtl = {
    gpg = 3600;
    ssh = 3600;
  };
in
{
  home.packages =
    [ pkgs.yubikey-manager ]
    ++ (
      if isDarwin then
        [
          pkgs.pinentry_mac
          yknotify
          pkgs.terminal-notifier
        ]
      else
        [ ]
    );

  programs.gpg = {
    enable = true;
    scdaemonSettings =
      {
        disable-ccid = true;
      }
      // (
        if isDarwin then
          {
            pcsc-shared = true;
            disable-application = "piv";
          }
        else
          { }
      );

    settings = {
      keyid-format = "0xlong";
      with-fingerprint = true;
      personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";
      cert-digest-algo = "SHA512";
      default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      personal-cipher-preferences = "AES256 AES192 AES";
      fixed-list-mode = true;
      no-comments = true;
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      keyserver = "hkps://keys.openpgp.org";
    };
  };

  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableSshSupport = true;
    enableZshIntegration = false;
    enableExtraSocket = true;

    sshKeys = [
      "495B10388160753867D2B6F7CAED2ED08F4D4323"
    ];

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

    defaultCacheTtl = pinCacheTtl.gpg;
    maxCacheTtl = pinCacheTtl.gpg;
    defaultCacheTtlSsh = pinCacheTtl.ssh;
    maxCacheTtlSsh = pinCacheTtl.ssh;

    grabKeyboardAndMouse = true;
    noAllowExternalCache = true;

    extraConfig = ''
      allow-preset-passphrase
      allow-loopback-pinentry
    '';
  };

  programs.zsh.initContent = ''
    export GPG_TTY=$(tty)
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';

}
