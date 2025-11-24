{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  home.packages = [
    # Note: gnupg is automatically installed by programs.gpg.enable = true
    # Pinentry packages:
    # - macOS: pinentry_mac (native macOS GUI, works well with Ghostty)
    # - Linux: pinentry-curses (terminal-based, optimal for Ghostty)
    #          pinentry-gnome3 (graphical, for GNOME desktop environments)
    (platformLib.platformPackage pkgs.pinentry-curses pkgs.pinentry_mac)
  ];

  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
      # Cache the Yubikey PIN for 24 hours
      card-timeout = "86400";
    };
    # Note: default-key should be configured per-user via git or gpg config
    # settings = {
    #   default-key = "YOUR_GPG_KEY_ID";
    # };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableZshIntegration = true; # Integrate with ZSH for better shell experience
    pinentry.package = lib.mkForce (
      # Platform-specific pinentry selection:
      # - macOS: pinentry_mac provides native GUI prompts
      # - Linux: pinentry-curses provides terminal-based prompts (better for Ghostty)
      platformLib.platformPackage pkgs.pinentry-curses pkgs.pinentry_mac
    );

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
  # Configure your SSH keys in ~/.gnupg/sshcontrol manually or via config
  # home.file.".gnupg/sshcontrol".text = ''
  #   YOUR_SSH_KEY_KEYGRIP
  # '';
}
