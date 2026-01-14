# NixOS MCP Configuration
#
# Enables MCP servers for NixOS hosts.
# The actual server definitions are in home/common/modules/mcp.nix
{
  # Enable MCP with default servers (no secrets required)
  services.mcp = {
    enable = true;

    # Default enabled servers (no secrets):
    # - memory, git, time, sqlite, everything

    # To enable servers that require secrets:
    # 1. Add secrets to secrets/secrets.yaml using: sops secrets/secrets.yaml
    # 2. Secrets are already configured in modules/shared/sops.nix
    # 3. Rebuild system: nh os switch
    # 4. Enable server below and rebuild again
    servers = {
      # ═══════════════════════════════════════════════════════════
      # ENABLED SERVERS (Secrets configured in SOPS)
      # ═══════════════════════════════════════════════════════════

      # Development & Documentation
      github.enabled = true; # GITHUB_TOKEN
      openai.enabled = true; # OPENAI_API_KEY
      docs.enabled = true; # OPENAI_API_KEY
      rustdocs.enabled = true; # OPENAI_API_KEY

      # Search & Research
      kagi.enabled = true; # KAGI_API_KEY

      # Utilities (no secrets required)
      filesystem.enabled = true;
      sequentialthinking.enabled = true;
      fetch.enabled = true;
      nixos.enabled = true;
      puppeteer.enabled = true; # Browser automation - no secrets required

      # ═══════════════════════════════════════════════════════════
      # AVAILABLE INTEGRATIONS (Add secrets to enable)
      # ═══════════════════════════════════════════════════════════

      # Project Management
      # linear.enabled = true;  # Requires: LINEAR_API_KEY
      # Get key: https://linear.app/settings/api

      # Communication
      # slack.enabled = true;  # Requires: SLACK_BOT_TOKEN, SLACK_TEAM_ID
      # Get credentials: https://api.slack.com/apps
      #
      # discord.enabled = true;  # Requires: DISCORD_BOT_TOKEN
      # Get token: https://discord.com/developers/applications

      # Research & Content
      # youtube.enabled = true;  # Requires: YOUTUBE_API_KEY
      # Get key: https://console.cloud.google.com/apis/credentials
      # Enable YouTube Data API v3

      # Database
      # postgres.enabled = true;  # Requires: POSTGRES_CONNECTION_STRING
      # Format: postgresql://user:password@host:port/database

      # Vector Databases (for RAG workflows)
      # qdrant.enabled = true;  # Requires: QDRANT_URL, QDRANT_API_KEY
      # Get credentials: https://cloud.qdrant.io/
      #
      # pinecone.enabled = true;  # Requires: PINECONE_API_KEY
      # Get key: https://www.pinecone.io/
      # Note: Choose qdrant OR pinecone based on your needs

      # Code Execution
      # e2b.enabled = true;  # Requires: E2B_API_KEY
      # Get key: https://e2b.dev/
      # Enables secure Python/JavaScript code execution

      # ═══════════════════════════════════════════════════════════
      # DISABLED ALTERNATIVES
      # ═══════════════════════════════════════════════════════════

      # brave.enabled = false;  # Disabled - using Kagi for search instead
    };
  };
}
