{
  lib,
  system,
  ...
}: let
  # Dedicated group for system secrets; use an existing root-owned group on
  # Darwin where dynamic group management is brittle.
  secretsGroup =
    if (lib.strings.hasSuffix "darwin" system)
    then "wheel"
    else "sops-secrets";

  mkSecret = {
    mode ? "0400",
    allowUserRead ? false,
  }: {
    mode =
      if allowUserRead
      then "0440"
      else mode;
    owner = "root";
    group = secretsGroup;
  };
in {
  # Common SOPS configuration for all platforms
  sops = {
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };
    defaultSopsFile = ../../secrets/secrets.yaml;

    secrets = {
      LATITUDE = mkSecret {};
      LONGITUDE = mkSecret {};
      HOME_ASSISTANT_BASE_URL = mkSecret {};
      GITHUB_PERSONAL_ACCESS_TOKEN = mkSecret {allowUserRead = true;};
    };
  };
}
