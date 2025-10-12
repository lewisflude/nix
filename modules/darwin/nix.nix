{
  config,
  username,
  ...
}: {
  environment.etc."nix/nix.custom.conf" = {
    text = ''
      trusted-users = root ${username}
      warn-dirty = false
    '';
  };
  nix = {
    enable = false;
    settings = {
      "access-tokens" = "github.com=${config.sops.secrets.GITHUB_PERSONAL_ACCESS_TOKEN.path}";
      sandbox = true;
      trusted-users = [
        "root"
        "@admin"
        username
      ];
    };
  };
}
