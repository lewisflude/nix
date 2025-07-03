{ pkgs, ... }:
{
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "524288";
    }
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "524288";
    }
  ];
  systemd.extraConfig = "DefaultLimitNOFILE=524288";
  security.pki.certificateFiles = [ ../mitmproxy-ca-cert.pem ];
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  boot.initrd.systemd.enable = true;

  programs._1password = {
    enable = true;
  };

  programs._1password-gui = {
    enable = true;
    package = pkgs._1password-gui-beta;
  };

  # GitHub access token should be configured via environment variable or SOPS
  # nix.settings = {
  #   access-tokens = "github.com=\${GITHUB_TOKEN}";
  # };
}
