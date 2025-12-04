{
  lib,
  system,
  username,
  ...
}:
let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;
  secretsDir = "${platformLib.dataDir username}/sops-nix";
in
{
  system.activationScripts.setupSOPSAge = {
    text = ''
      install -d -m 700 -o root -g wheel /var/lib/sops-nix
      install -d -m 700 -o ${username} -g staff ${secretsDir}
    '';
  };

  # Fix SOPS secret permissions on Darwin
  # sops-nix creates secrets with root:wheel, but we need admin group for user access
  system.activationScripts.fixSOPSSecretPermissions = {
    text = ''
      # Fix permissions for user-readable secrets
      if [ -d /run/secrets-for-users ]; then
        chmod 640 /run/secrets-for-users/OPENAI_API_KEY 2>/dev/null || true
        chgrp admin /run/secrets-for-users/OPENAI_API_KEY 2>/dev/null || true
        
        chmod 640 /run/secrets-for-users/GITHUB_TOKEN 2>/dev/null || true
        chgrp admin /run/secrets-for-users/GITHUB_TOKEN 2>/dev/null || true
        
        chmod 640 /run/secrets-for-users/KAGI_API_KEY 2>/dev/null || true
        chgrp admin /run/secrets-for-users/KAGI_API_KEY 2>/dev/null || true
        
        chmod 640 /run/secrets-for-users/OBSIDIAN_API_KEY 2>/dev/null || true
        chgrp admin /run/secrets-for-users/OBSIDIAN_API_KEY 2>/dev/null || true
        
        chmod 640 /run/secrets-for-users/CIRCLECI_TOKEN 2>/dev/null || true
        chgrp admin /run/secrets-for-users/CIRCLECI_TOKEN 2>/dev/null || true
      fi
    '';
  };
}
