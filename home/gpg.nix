{ pkgs, ... }:
{
  home.packages = [
    pkgs.gnupg
    pkgs.pinentry_mac
  ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
    pinentry.package = pkgs.pinentry_mac;
    extraConfig = ''
      allow-preset-passphrase
      grab
      no-allow-external-cache
    '';
  };

  programs.gpg = {
    enable = true;
    settings = {
      default-key = "D4DD67DDDBAEF83F";
      use-agent = true;
    };
  };
}
