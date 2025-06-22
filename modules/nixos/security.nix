{pkgs, ...}: {
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

  nix.settings = {
    access-tokens = "github.com=REDACTED_GITHUB_TOKEN";
  };
}
