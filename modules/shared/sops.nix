{
  config,
  lib,
  ...
}: let
  isDarwin = lib.strings.hasSuffix "darwin" config.host.system;
  secretsGroup =
    if isDarwin
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
    neededForUsers = allowUserRead;
  };
in {
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
      GITHUB_TOKEN = mkSecret {allowUserRead = true;};
    };
  };

  # Validation assertions for SOPS configuration
  assertions = [
    {
      assertion = config.sops.secrets != {} -> config.sops.age.keyFile != null;
      message = "SOPS secrets are defined but no age key file is specified";
    }
    {
      assertion = config.sops.secrets != {} -> config.sops.defaultSopsFile != null;
      message = "SOPS secrets are defined but no default SOPS file is specified";
    }
    {
      assertion =
        config.sops.secrets != {}
        -> builtins.pathExists (toString config.sops.defaultSopsFile);
      message = "SOPS default file does not exist: ${toString config.sops.defaultSopsFile}";
    }
  ];
}
