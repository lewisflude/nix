{ pkgs, ... }:
{
  home.packages = [
    pkgs.gnupg
    pkgs.pinentry_mac
  ];

  programs.gpg = {
    enable = true;
    settings = {
      default-key = "D4DD67DDDBAEF83F";
      use-agent = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;

    pinentry.package = pkgs.pinentry_mac;

    defaultCacheTtl = 28800;
    maxCacheTtl = 86400;

    extraConfig = ''
      default-cache-ttl-ssh 3600
      max-cache-ttl-ssh     7200
      allow-preset-passphrase
      grab
      no-allow-external-cache
    '';
  };

}
