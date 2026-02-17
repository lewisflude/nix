# SOPS secrets management - Dendritic Pattern
# Single file containing NixOS, Darwin, and home-manager configurations
{ config, ... }:
let
  inherit (config) username myLib;

  mkSecret =
    {
      mode ? "0400",
      allowUserRead ? false,
    }:
    {
      mode = if allowUserRead then "0440" else mode;
      owner = if allowUserRead then "root" else username;
      group = "sops-secrets";
    };
in
{
  # ===========================================================================
  # NixOS: SOPS configuration
  # ===========================================================================
  flake.modules.nixos.sops =
    { lib, ... }:
    {
      sops = {
        age = {
          keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
          generateKey = lib.mkDefault true;
          sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
        gnupg.sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
        defaultSopsFile = ../secrets/secrets.yaml;
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

  # ===========================================================================
  # Darwin: SOPS configuration
  # ===========================================================================
  flake.modules.darwin.sops =
    let
      mkDarwinSecret = {
        mode = "0640";
        owner = username;
        group = "admin";
      };
    in
    {
      sops = {
        age = {
          keyFile = "${myLib.dataDir "aarch64-darwin" username}/sops-nix/key.txt";
          generateKey = true;
          sshKeyPaths = [ ]; # Disable SSH key auto-detection on Darwin
        };
        gnupg.sshKeyPaths = [ ]; # Disable gnupg auto-detection on Darwin
        defaultSopsFile = ../secrets/secrets.yaml;
        secrets = {
          CIRCLECI_TOKEN = mkDarwinSecret;
          GITHUB_TOKEN = mkDarwinSecret;
          KAGI_API_KEY = mkDarwinSecret;
          OPENAI_API_KEY = mkDarwinSecret;
          HOME_ASSISTANT_TOKEN = mkDarwinSecret;
        };
      };
    };

  # ===========================================================================
  # Home-manager: SOPS configuration
  # ===========================================================================
  flake.modules.homeManager.sops =
    { pkgs, ... }@hmArgs:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      dataDir = myLib.dataDir system hmArgs.config.home.username;
      keyFilePath =
        if pkgs.stdenv.isDarwin then "${dataDir}/sops-nix/key.txt" else "/var/lib/sops-nix/key.txt";
    in
    {
      sops.age = {
        keyFile = keyFilePath;
        sshKeyPaths = [ ];
      };

      # Install sops CLI tool for editing secrets
      home.packages = [ pkgs.sops ];
    };
}
