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
    (platformLib.platformPackage pkgs.pinentry-gnome3 pkgs.pinentry_mac)
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
    pinentry.package = lib.mkForce (platformLib.platformPackage pkgs.pinentry-gnome3 pkgs.pinentry_mac);
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

  # SSH control file for GPG agent
  # Configure your SSH keys in ~/.gnupg/sshcontrol manually or via config
  # home.file.".gnupg/sshcontrol".text = ''
  #   YOUR_SSH_KEY_KEYGRIP
  # '';
}
