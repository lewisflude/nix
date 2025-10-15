{
  config,
  lib,
  hostSystem,
  ...
}: let
  isDarwin = lib.strings.hasSuffix "darwin" hostSystem;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
  platformLib = import ../../lib/functions.nix {
    inherit lib;
    system = hostSystem;
  };
  keyFilePath =
    if isDarwin
    then "${platformLib.dataDir config.host.username}/sops-nix/key.txt"
    else "/var/lib/sops-nix/key.txt";
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
  # Only configure system-level sops on Linux (NixOS)
  # Darwin uses home-manager sops for user-level secrets only
  sops = lib.mkIf isLinux {
    age = {
      keyFile = keyFilePath;
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
  assertions = lib.optionals isLinux [
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
        config.sops.secrets != {} -> builtins.pathExists (toString config.sops.defaultSopsFile);
      message = "SOPS default file does not exist: ${toString config.sops.defaultSopsFile}";
    }
  ];
}
