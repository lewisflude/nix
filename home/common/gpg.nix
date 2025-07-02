{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gnupg
    (if pkgs.stdenv.isDarwin then pinentry_mac else pinentry-curses)
  ];

  programs.gpg = {
    enable = true;

    # https://support.yubico.com/hc/en-us/articles/4819584884124-Resolving-GPG-s-CCID-conflicts
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

    pinentry.package = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-gnome3;

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
