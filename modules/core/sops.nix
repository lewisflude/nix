# SOPS secrets management configuration
# Uses top-level config.username from modules/meta.nix
{ config, ... }:
let
  inherit (config) username;

  mkSecret =
    {
      mode ? "0400",
      allowUserRead ? false,
    }:
    {
      mode = if allowUserRead then "0440" else mode;
      owner = if allowUserRead then "root" else username;
      group = if allowUserRead then "sops-secrets" else "sops-secrets";
    };
in
{
  # NixOS SOPS configuration
  flake.modules.nixos.base =
    { lib, ... }:
    {
      sops = {
        age = {
          keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
          generateKey = lib.mkDefault true;
          sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
        gnupg.sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
        defaultSopsFile = ../../secrets/secrets.yaml;
        secrets = {
          CIRCLECI_TOKEN = mkSecret { allowUserRead = true; };
          GITHUB_TOKEN = mkSecret { allowUserRead = true; };
          LATITUDE = mkSecret { };
          LONGITUDE = mkSecret { };
          HOME_ASSISTANT_BASE_URL = mkSecret { };
          HOME_ASSISTANT_TOKEN = mkSecret { allowUserRead = true; };
          KAGI_API_KEY = mkSecret { allowUserRead = true; };
          OBSIDIAN_API_KEY = mkSecret { allowUserRead = true; };
          OPENAI_API_KEY = mkSecret { allowUserRead = true; };
          restic-password = mkSecret { allowUserRead = true; };
          LINEAR_API_KEY = mkSecret { allowUserRead = true; };
          SLACK_BOT_TOKEN = mkSecret { allowUserRead = true; };
          SLACK_TEAM_ID = mkSecret { allowUserRead = true; };
          DISCORD_BOT_TOKEN = mkSecret { allowUserRead = true; };
          YUTU_CREDENTIAL = mkSecret { allowUserRead = true; };
          YUTU_CACHE_TOKEN = mkSecret { allowUserRead = true; };
          POSTGRES_CONNECTION_STRING = mkSecret { allowUserRead = true; };
          QDRANT_URL = mkSecret { allowUserRead = true; };
          QDRANT_API_KEY = mkSecret { allowUserRead = true; };
          PINECONE_API_KEY = mkSecret { allowUserRead = true; };
          E2B_API_KEY = mkSecret { allowUserRead = true; };
        };
      };

      # Create sops-secrets group for user-readable secrets
      users.groups.sops-secrets = { };
      users.users.${username}.extraGroups = [ "sops-secrets" ];
    };

  # Darwin SOPS configuration
  flake.modules.darwin.base = {
    sops = {
      age = {
        keyFile = "/Users/${username}/Library/Application Support/sops-nix/key.txt";
        generateKey = true;
        sshKeyPaths = [ ]; # Disable SSH key auto-detection on Darwin
      };
      gnupg.sshKeyPaths = [ ]; # Disable gnupg auto-detection on Darwin
      defaultSopsFile = ../../secrets/secrets.yaml;
      secrets = {
        # Same secrets as NixOS but with Darwin-appropriate modes
        CIRCLECI_TOKEN = {
          mode = "0640";
          owner = username;
          group = "admin";
        };
        GITHUB_TOKEN = {
          mode = "0640";
          owner = username;
          group = "admin";
        };
        KAGI_API_KEY = {
          mode = "0640";
          owner = username;
          group = "admin";
        };
        OPENAI_API_KEY = {
          mode = "0640";
          owner = username;
          group = "admin";
        };
        HOME_ASSISTANT_TOKEN = {
          mode = "0640";
          owner = username;
          group = "admin";
        };
      };
    };
  };
}
