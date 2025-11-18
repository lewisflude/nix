{
  config,
  lib,
  hostSystem,
  ...
}:
let
  isDarwin = lib.strings.hasSuffix "darwin" hostSystem;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  keyFilePath =
    if isDarwin then
      "${platformLib.dataDir config.host.username}/sops-nix/key.txt"
    else
      "/var/lib/sops-nix/key.txt";
  mkSecret =
    {
      mode ? (if isDarwin then "0640" else "0400"),
      allowUserRead ? false,
    }:
    let
      resolvedMode =
        if isDarwin then
          mode
        else if allowUserRead then
          "0440"
        else
          mode;
      resolvedOwner = config.host.username;
      # On NixOS with neededForUsers, we need to set the owner to the user, not root
      # This allows the user to read their own secrets
      resolvedGroup = if isDarwin then "wheel" else "sops-secrets";
    in
    {
      mode = resolvedMode;
      owner = resolvedOwner;
      group = resolvedGroup;
      neededForUsers = allowUserRead;
    };
in
{
  sops = lib.mkIf (isLinux || isDarwin) (
    {
      age = {
        keyFile = keyFilePath;
        generateKey = true;
      };
      defaultSopsFile = ../../secrets/secrets.yaml;
      secrets = {
        CIRCLECI_TOKEN = mkSecret { allowUserRead = true; };
        GITHUB_TOKEN = mkSecret { allowUserRead = true; };
        LATITUDE = mkSecret { };
        LONGITUDE = mkSecret { };
        HOME_ASSISTANT_BASE_URL = mkSecret { };
        KAGI_API_KEY = mkSecret { allowUserRead = true; };
        OBSIDIAN_API_KEY = mkSecret { allowUserRead = true; };
        OPENAI_API_KEY = mkSecret { allowUserRead = true; };
      };
    }
    // lib.optionalAttrs isLinux { sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; }
  );

  assertions = lib.optionals (isLinux || isDarwin) [
    {
      assertion = config.sops.secrets != { } -> config.sops.age.keyFile != null;
      message = "SOPS secrets are defined but no age key file is specified";
    }
    {
      assertion = config.sops.secrets != { } -> config.sops.defaultSopsFile != null;
      message = "SOPS secrets are defined but no default SOPS file is specified";
    }
    {
      assertion =
        config.sops.secrets != { } -> builtins.pathExists (toString config.sops.defaultSopsFile);
      message = "SOPS default file does not exist: ${toString config.sops.defaultSopsFile}";
    }
  ];
}
