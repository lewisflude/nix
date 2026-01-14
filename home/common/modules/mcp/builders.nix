# MCP Server Builder Functions
{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) optionalAttrs;

  # Simple secret wrapper - one function instead of four builders
  # Secrets are deployed to /run/secrets/ with group ownership (admin on macOS, sops-secrets on Linux)
  # We check at runtime, not build time, so wrappers always work if secret exists
  wrapWithSecret =
    name: cmd: secretName:
    pkgs.writeShellScript "${name}-mcp" ''
      set -euo pipefail

      # Detect platform for better error messages
      if [ "$(uname)" = "Darwin" ]; then
        EXPECTED_GROUP="admin"
      else
        EXPECTED_GROUP="sops-secrets"
      fi

      # Secrets are in /run/secrets/ with group ownership
      SECRET_PATH="/run/secrets/${secretName}"
      if [ ! -r "$SECRET_PATH" ]; then
        echo "Error: ${name} requires ${secretName} secret" >&2
        echo "Secret not found or not readable at $SECRET_PATH" >&2
        echo "Ensure you're in the '$EXPECTED_GROUP' group and the secret is configured in SOPS" >&2
        echo "Current groups: $(id -Gn | tr ' ' ',')" >&2
        exit 1
      fi

      export ${secretName}="$(cat "$SECRET_PATH")"

      # Set NPM_CONFIG_REGISTRY for npx commands if not already set
      # This ensures npx uses the public registry even if user has CodeArtifact configured
      if echo "${cmd}" | grep -q "npx"; then
        export NPM_CONFIG_REGISTRY="''${NPM_CONFIG_REGISTRY:-https://registry.npmjs.org/}"
        # Use a version-specific npx cache to avoid native module version mismatches
        # Extract Node.js version from the npx path and use it in cache directory
        # The command is a full path like /nix/store/.../nodejs_20/bin/npx
        NPX_PATH="$(echo "${cmd}" | awk '{print $1}')"
        if [ -n "$NPX_PATH" ] && [ -f "$NPX_PATH" ]; then
          NODE_BIN="$(dirname "$NPX_PATH")/node"
          if [ -f "$NODE_BIN" ]; then
            NODE_VERSION="$("$NODE_BIN" --version 2>/dev/null | tr -d 'v' | tr '.' '_' || echo "unknown")"
            export NPX_CACHE_DIR="''${HOME}/.npm/_npx-''${NODE_VERSION}"
          fi
        fi
      fi

      exec ${cmd} "$@"
    '';

  # Build an MCP server config entry
  mkServerConfig =
    name: serverCfg:
    let
      # Validate required fields
      hasCommand = serverCfg.command or null != null;

      # Determine the command
      command =
        if !hasCommand then
          throw "MCP server '${name}' has no command defined. This shouldn't happen after merge."
        else if (serverCfg.secret or null) != null then
          "${wrapWithSecret name serverCfg.command serverCfg.secret}"
        else
          serverCfg.command;

      # Get args and env with defaults
      args = serverCfg.args or [ ];
      env = serverCfg.env or { };
    in
    {
      inherit command;
    }
    // optionalAttrs (args != [ ]) { inherit args; }
    // optionalAttrs (env != { }) { inherit env; };
in
{
  inherit wrapWithSecret mkServerConfig;
}
