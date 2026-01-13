# MCP Server Builder Functions
{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) optionalAttrs;

  # Simple secret wrapper - one function instead of four builders
  # Secrets are deployed to /run/secrets-for-users/ (with neededForUsers = true)
  # We check at runtime, not build time, so wrappers always work if secret exists
  wrapWithSecret =
    name: cmd: secretName:
    pkgs.writeShellScript "${name}-mcp" ''
      set -euo pipefail

      # Secrets are in /run/secrets/ with sops-secrets group ownership
      SECRET_PATH="/run/secrets/${secretName}"
      if [ ! -r "$SECRET_PATH" ]; then
        echo "Error: ${name} requires ${secretName} secret" >&2
        echo "Secret not found or not readable at $SECRET_PATH" >&2
        echo "Ensure you're in the 'sops-secrets' group and the secret is configured in SOPS" >&2
        exit 1
      fi

      export ${secretName}="$(cat "$SECRET_PATH")"
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
