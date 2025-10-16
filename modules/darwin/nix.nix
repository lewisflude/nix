{username, ...}: {
  environment.etc."nix/nix.custom.conf" = {
    text = ''
      trusted-users = root ${username}
      warn-dirty = false
    '';
  };
  nix.enable = false;
  nix.settings = {
    sandbox = true;
    trusted-users = [
      "root"
      "@admin"
      username
    ];
  };
}
