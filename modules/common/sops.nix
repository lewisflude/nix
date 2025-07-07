{
  lib,
  system,
  ...
}:
let
  # Platform-specific group configuration
  platformGroup = if (lib.strings.hasSuffix "darwin" system) then "wheel" else "users";

  # Common secret configuration
  mkSecret =
    {
      mode ? "0400",
      allowUserRead ? false,
    }:
    {
      mode = if allowUserRead then "0440" else mode;
      owner = "root";
      group = platformGroup;
    };
in
{
  # Common SOPS configuration for all platforms
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/secrets.yaml;

    secrets = {
      LATITUDE = mkSecret { };
      LONGITUDE = mkSecret { };
      HOME_ASSISTANT_BASE_URL = mkSecret { };
      GITHUB_PERSONAL_ACCESS_TOKEN = mkSecret { allowUserRead = true; };
    };
  };
}
