# Darwin MCP Configuration
#
# Enables ALL MCP servers for macOS hosts.
# The actual server definitions are in home/common/modules/mcp.nix
{
  # Enable MCP with ALL available servers
  services.mcp = {
    enable = true;

    servers = {
      # ═══════════════════════════════════════════════════════════
      # CORE SERVERS (enabled by default, no secrets)
      # ═══════════════════════════════════════════════════════════
      # memory, git, time, sqlite, everything - always enabled

      # ═══════════════════════════════════════════════════════════
      # DEVELOPMENT & DOCUMENTATION
      # ═══════════════════════════════════════════════════════════
      github.enabled = true; # GITHUB_TOKEN
      openai.enabled = true; # OPENAI_API_KEY
      docs.enabled = true; # OPENAI_API_KEY
      # rustdocs.enabled = true; # TEMPORARILY DISABLED: upstream apple_sdk_11_0 deprecation

      # ═══════════════════════════════════════════════════════════
      # SEARCH & RESEARCH
      # ═══════════════════════════════════════════════════════════
      kagi.enabled = true; # KAGI_API_KEY
      brave.enabled = true; # BRAVE_API_KEY

      # ═══════════════════════════════════════════════════════════
      # UTILITIES (no secrets required)
      # ═══════════════════════════════════════════════════════════
      filesystem.enabled = true;
      sequentialthinking.enabled = true;
      fetch.enabled = true;
      nixos.enabled = true;
      puppeteer.enabled = true; # Browser automation

      # ═══════════════════════════════════════════════════════════
      # PROJECT MANAGEMENT
      # ═══════════════════════════════════════════════════════════
      linear.enabled = true; # LINEAR_API_KEY

      # ═══════════════════════════════════════════════════════════
      # COMMUNICATION
      # ═══════════════════════════════════════════════════════════
      slack.enabled = true; # SLACK_BOT_TOKEN, SLACK_TEAM_ID
      discord.enabled = true; # DISCORD_BOT_TOKEN

      # ═══════════════════════════════════════════════════════════
      # RESEARCH & CONTENT
      # ═══════════════════════════════════════════════════════════
      youtube.enabled = true; # YOUTUBE_API_KEY

      # ═══════════════════════════════════════════════════════════
      # DATABASE
      # ═══════════════════════════════════════════════════════════
      postgres.enabled = true; # POSTGRES_CONNECTION_STRING

      # ═══════════════════════════════════════════════════════════
      # VECTOR DATABASES (for RAG workflows)
      # ═══════════════════════════════════════════════════════════
      qdrant.enabled = true; # QDRANT_URL, QDRANT_API_KEY
      pinecone.enabled = true; # PINECONE_API_KEY

      # ═══════════════════════════════════════════════════════════
      # CODE EXECUTION
      # ═══════════════════════════════════════════════════════════
      e2b.enabled = true; # E2B_API_KEY
    };
  };
}
