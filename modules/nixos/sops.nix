{ username, ... }: {
  # Ensure the system secrets group exists and contains the primary user.
  users.groups."sops-secrets".members = [ username ];

  # Ensure host-managed key directory exists with strict permissions.
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root -"
  ];
}
