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
      brave.enabled = false; # BRAVE_API_KEY - NOT CONFIGURED

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
      slack.enabled = false; # SLACK_BOT_TOKEN, SLACK_TEAM_ID - PLACEHOLDER VALUES
      discord.enabled = false; # DISCORD_BOT_TOKEN - PLACEHOLDER VALUE

      # ═══════════════════════════════════════════════════════════
      # RESEARCH & CONTENT
      # ═══════════════════════════════════════════════════════════
      youtube.enabled = true; # YOUTUBE_API_KEY

      # ═══════════════════════════════════════════════════════════
      # DATABASE
      # ═══════════════════════════════════════════════════════════
      postgres.enabled = false; # POSTGRES_CONNECTION_STRING - PLACEHOLDER VALUE

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
