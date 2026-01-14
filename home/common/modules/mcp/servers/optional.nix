# Optional MCP Servers (disabled by default, no secrets required)
{
  pkgs,
  config,
  ...
}:
{
  # Secure file operations with configurable access controls
  # Note: Configure allowed directories in your platform-specific config
  filesystem = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-filesystem"
      config.home.homeDirectory
    ];
    enabled = false; # Disabled by default for security - enable in platform config if needed
  };

  # Dynamic and reflective problem-solving through thought sequences
  sequentialthinking = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-sequential-thinking"
    ];
    enabled = false; # Disabled by default - enable if needed
  };

  # Web content fetching (community alternative)
  fetch = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "mcp-server-fetch-typescript"
    ];
    enabled = false; # Disabled - enable if needed
  };

  # NixOS package search (requires uv)
  nixos = {
    command = "${pkgs.uv}/bin/uvx";
    args = [ "mcp-nixos" ];
    enabled = false; # Disabled - requires uv package
  };

  # Puppeteer - Browser automation and web scraping
  # No API key required - uses local Chromium
  # Navigate pages, take screenshots, interact with forms, capture console logs
  puppeteer = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-puppeteer"
    ];
    enabled = false; # Disabled by default - enable if needed for browser automation
  };
}
