# Integration MCP Servers (disabled by default, require secrets)
# Project management, communication, and research tools
{
  pkgs,
  ...
}:
let
  # Multi-secret wrapper for servers that need multiple secrets
  wrapMultiSecret =
    name: cmd: secrets:
    pkgs.writeShellScript "${name}-mcp" ''
      set -euo pipefail

      # Detect platform for better error messages
      if [ "$(uname)" = "Darwin" ]; then
        EXPECTED_GROUP="admin"
      else
        EXPECTED_GROUP="sops-secrets"
      fi

      ${pkgs.lib.concatMapStringsSep "\n" (secret: ''
        SECRET_PATH="/run/secrets/${secret}"
        if [ ! -r "$SECRET_PATH" ]; then
          echo "Error: ${name} requires ${secret} secret" >&2
          echo "Secret not found or not readable at $SECRET_PATH" >&2
          echo "Ensure you're in the '$EXPECTED_GROUP' group and the secret is configured in SOPS" >&2
          echo "Current groups: $(id -Gn | tr ' ' ',')" >&2
          exit 1
        fi
        export ${secret}="$(cat "$SECRET_PATH")"
      '') secrets}

      # Set NPM_CONFIG_REGISTRY for npx commands if not already set
      # This ensures npx uses the public registry even if user has CodeArtifact configured
      if echo "${cmd}" | grep -q "npx"; then
        export NPM_CONFIG_REGISTRY="''${NPM_CONFIG_REGISTRY:-https://registry.npmjs.org/}"
      fi

      exec ${cmd} "$@"
    '';
in
{
  # Linear - Project management integration
  # Get API key: https://linear.app/settings/api
  linear = {
    command = toString (
      wrapMultiSecret "linear" "${pkgs.nodejs}/bin/npx -y mcp-server-linear" [
        "LINEAR_API_KEY"
      ]
    );
    args = [ ];
    enabled = false;
  };

  # Slack - Workspace integration
  # Get credentials: https://api.slack.com/apps (create app, add bot token)
  # Requires both bot token and team ID
  slack = {
    command = toString (
      wrapMultiSecret "slack" "${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-slack" [
        "SLACK_BOT_TOKEN"
        "SLACK_TEAM_ID"
      ]
    );
    args = [ ];
    enabled = false;
  };

  # Discord - Server management and messaging
  # Get token: https://discord.com/developers/applications (create app, bot token)
  discord = {
    command = toString (
      wrapMultiSecret "discord" "${pkgs.nodejs}/bin/npx -y @quantgeekdev/discord-mcp" [
        "DISCORD_BOT_TOKEN"
      ]
    );
    args = [ ];
    enabled = false;
  };

  # YouTube - Video search, transcripts, and captions
  # Get API key: https://console.cloud.google.com/apis/credentials (enable YouTube Data API v3)
  youtube = {
    command = toString (
      wrapMultiSecret "youtube" "${pkgs.nodejs}/bin/npx -y mcp-server-youtube" [ "YOUTUBE_API_KEY" ]
    );
    args = [ ];
    enabled = false;
  };

  # PostgreSQL - Database operations
  # Connection string format: postgresql://user:password@host:port/database
  postgres = {
    command = toString (
      wrapMultiSecret "postgres" "${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-postgres" [
        "POSTGRES_CONNECTION_STRING"
      ]
    );
    args = [ ];
    enabled = false;
  };

  # Qdrant - Vector database for RAG workflows
  # Get credentials: https://cloud.qdrant.io/ (create cluster, get URL and API key)
  qdrant = {
    command = toString (
      wrapMultiSecret "qdrant" "${pkgs.nodejs}/bin/npx -y mcp-server-qdrant" [
        "QDRANT_URL"
        "QDRANT_API_KEY"
      ]
    );
    args = [ ];
    enabled = false;
  };

  # Pinecone - Alternative vector database for RAG
  # Get API key: https://www.pinecone.io/ (create index, get API key)
  # Note: Alternative to qdrant, choose one based on your needs
  pinecone = {
    command = toString (
      wrapMultiSecret "pinecone" "${pkgs.nodejs}/bin/npx -y mcp-server-pinecone" [ "PINECONE_API_KEY" ]
    );
    args = [ ];
    enabled = false;
  };

  # E2B - Secure code execution sandbox
  # Get API key: https://e2b.dev/ (sign up, get API key from dashboard)
  # Enables safe execution of Python/JavaScript code with package installation
  e2b = {
    command = toString (
      wrapMultiSecret "e2b" "${pkgs.nodejs}/bin/npx -y @e2b/mcp-server" [ "E2B_API_KEY" ]
    );
    args = [ ];
    enabled = false;
  };
}
