# Shared constants used across the Nix configuration
# This file centralizes commonly used values to avoid duplication

{
  # GPG and SSH keys
  keys = {
    gpg = {
      primary = "48B34CF9C735A6AE";
      sshControl = "495B10388160753867D2B6F7CAED2ED08F4D4323";
    };
  };

  # Common directory paths (relative to home)
  paths = {
    code = "Code";
    config = ".config";
    documents = "Documents";
    nixConfig = ".config/nix";
  };

  # Project-specific paths
  projects = {
    dexWeb = "Code/dex-web";
  };

  # NH (Nix Helper) configuration
  nh = {
    cleanArgs = "--keep-since 4d --keep 3";
  };

  # Editor configuration
  editor = {
    default = "hx"; # Helix
  };
}
