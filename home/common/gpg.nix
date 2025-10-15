{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
in {
  home.packages = with pkgs; [
    gnupg
    (platformLib.platformPackage pinentry-curses pinentry_mac)
  ];
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
    };
    settings = {
      default-key = "48B34CF9C735A6AE";
    };
  };
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = lib.mkForce (platformLib.platformPackage pkgs.pinentry-gnome3 pkgs.pinentry_mac);
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    extraConfig = ''
      default-cache-ttl-ssh 3600
      max-cache-ttl-ssh     7200
      allow-preset-passphrase
      grab
      allow-loopback-pinentry
    '';
  };
  home.file.".gnupg/sshcontrol".text = ''
    495B10388160753867D2B6F7CAED2ED08F4D4323
  '';
}
