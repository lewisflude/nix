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
    extraConfig = ''
      pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
      allow-preset-passphrase
      enable-ssh-support
      max-cache-ttl 7200
      default-cache-ttl 3600
    '';
  };

  programs.gpg = {
    enable = true;
    settings = {
      default-key = "01E0A6442301AD277C5A0EB3066E74CC9ACF910C";
      use-agent = true;
    };
  };
}
