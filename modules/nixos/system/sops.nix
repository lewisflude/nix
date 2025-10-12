{username, ...}: {
  users.groups."sops-secrets".members = [username];
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root -"
  ];
}
