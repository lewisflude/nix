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

  # YouTube - Full-featured MCP server using yutu (Go-based)
  # Setup:
  #   1. Create OAuth client in Google Cloud Console (https://console.cloud.google.com)
  #   2. Enable YouTube Data API v3, YouTube Analytics API (optional), YouTube Reporting API (optional)
  #   3. Create OAuth 2.0 Client ID with redirect URI: http://localhost:8216
  #   4. Download client_secret.json and run: yutu auth --credential client_secret.json
  #   5. Store both client_secret.json and youtube.token.json contents in SOPS
  # Package: yutu (https://github.com/eat-pray-ai/yutu)
  # Note: yutu expects file paths via YUTU_CREDENTIAL and YUTU_CACHE_TOKEN env vars
  youtube = {
    command = toString (
      pkgs.writeShellScript "youtube-mcp" ''
        set -euo pipefail

        # Detect platform for better error messages
        if [ "$(uname)" = "Darwin" ]; then
          EXPECTED_GROUP="admin"
        else
          EXPECTED_GROUP="sops-secrets"
        fi

        # Check secrets exist
        if [ ! -r "/run/secrets/YUTU_CREDENTIAL" ] || [ ! -r "/run/secrets/YUTU_CACHE_TOKEN" ]; then
          echo "Warning: yutu MCP server disabled - YUTU_CREDENTIAL or YUTU_CACHE_TOKEN not available" >&2
          echo "Secrets not found or not readable" >&2
          echo "To enable this server:" >&2
          echo "  1. Ensure you're in the '$EXPECTED_GROUP' group: $(id -Gn | tr ' ' ',')" >&2
          echo "  2. Configure secrets in SOPS (secrets/secrets.yaml)" >&2
          echo "  3. Rebuild system and restart MCP client" >&2
          exit 0
        fi

        # yutu expects env vars to point to file paths, not contain the content
        export YUTU_CREDENTIAL="/run/secrets/YUTU_CREDENTIAL"
        export YUTU_CACHE_TOKEN="/run/secrets/YUTU_CACHE_TOKEN"

        exec ${pkgs.yutu}/bin/yutu mcp "$@"
      ''
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

  # Qdrant - Vector database for RAG workflows with semantic memory
  # Get credentials: https://cloud.qdrant.io/ (create cluster, get URL and API key)
  # Package: mcp-server-qdrant (Python-based, uses uvx)
  # Supports local mode with QDRANT_LOCAL_PATH or cloud with QDRANT_URL
  qdrant = {
    command = toString (
      wrapMultiSecret "qdrant" "${pkgs.uv}/bin/uvx mcp-server-qdrant" [
        "QDRANT_URL"
        "QDRANT_API_KEY"
      ]
    );
    args = [ ];
    enabled = false;
  };

  # Pinecone - Vector database for RAG workflows with integrated inference
  # Get API key: https://app.pinecone.io/ (generate API key in console)
  # Package: @pinecone-database/mcp
  # Note: Only supports indexes with integrated inference
  pinecone = {
    command = toString (
      wrapMultiSecret "pinecone" "${pkgs.nodejs}/bin/npx -y @pinecone-database/mcp" [
        "PINECONE_API_KEY"
      ]
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
