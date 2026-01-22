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
      # memory, git - kept enabled
      time.enabled = false; # DISABLED: Rarely needed
      sqlite.enabled = false; # DISABLED: Not needed for Nix development
      everything.enabled = false; # DISABLED: Demo/testing server

      # ═══════════════════════════════════════════════════════════
      # DEVELOPMENT & DOCUMENTATION
      # ═══════════════════════════════════════════════════════════
      github.enabled = true; # GITHUB_TOKEN - KEPT for GitHub API integration
      openai.enabled = false; # DISABLED: Redundant with Claude
      docs.enabled = true; # OPENAI_API_KEY
      # rustdocs.enabled = true; # TEMPORARILY DISABLED: upstream apple_sdk_11_0 deprecation

      # ═══════════════════════════════════════════════════════════
      # SEARCH & RESEARCH
      # ═══════════════════════════════════════════════════════════
      kagi.enabled = true; # KAGI_API_KEY - KEPT as requested
      brave.enabled = false; # BRAVE_API_KEY - NOT CONFIGURED

      # ═══════════════════════════════════════════════════════════
      # UTILITIES (no secrets required)
      # ═══════════════════════════════════════════════════════════
      filesystem.enabled = true;
      sequentialthinking.enabled = true;
      fetch.enabled = false; # DISABLED: Native capabilities usually sufficient
      nixos.enabled = true;
      puppeteer.enabled = false; # DISABLED: Browser automation not needed
      wayland.enabled = true; # Wayland screenshot, analysis, and input control

      # ═══════════════════════════════════════════════════════════
      # PROJECT MANAGEMENT
      # ═══════════════════════════════════════════════════════════
      linear.enabled = false; # DISABLED: Not needed for this project

      # ═══════════════════════════════════════════════════════════
      # COMMUNICATION
      # ═══════════════════════════════════════════════════════════
      slack.enabled = false; # SLACK_BOT_TOKEN, SLACK_TEAM_ID - PLACEHOLDER VALUES
      discord.enabled = false; # DISCORD_BOT_TOKEN - PLACEHOLDER VALUE

      # ═══════════════════════════════════════════════════════════
      # RESEARCH & CONTENT
      # ═══════════════════════════════════════════════════════════
      youtube.enabled = false; # DISABLED: Video management not needed

      # ═══════════════════════════════════════════════════════════
      # DATABASE
      # ═══════════════════════════════════════════════════════════
      postgres.enabled = false; # POSTGRES_CONNECTION_STRING - PLACEHOLDER VALUE

      # ═══════════════════════════════════════════════════════════
      # VECTOR DATABASES (for RAG workflows)
      # ═══════════════════════════════════════════════════════════
      qdrant.enabled = false; # DISABLED: Vector storage not needed
      pinecone.enabled = false; # DISABLED: Vector database not needed

      # ═══════════════════════════════════════════════════════════
      # CODE EXECUTION
      # ═══════════════════════════════════════════════════════════
      e2b.enabled = false; # DISABLED: Remote sandbox not needed
    };
  };
}
