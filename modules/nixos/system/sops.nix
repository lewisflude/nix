{username, ...}: {
  users.groups."sops-secrets".members = [username];
  users.users.${username}.extraGroups = ["keys"];
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root -"
  ];
}
