{username, ...}: {
  nix.enable = true;
  nix.settings = {
    sandbox = true;
    trusted-users = [
      "root"
      "@wheel"
      username
    ];
    use-xdg-base-directories = true;
  };
}
