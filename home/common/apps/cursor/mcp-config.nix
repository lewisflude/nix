# MCP (Model Context Protocol) Configuration for Cursor
# This file defines the MCP servers configuration that will be written to ~/.cursor/mcp.json

{ ... }:
{
  # MCP servers configuration
  mcpServers = {
    "sequential-thinking" = {
      "command" = "docker";
      "args" = [
        "run"
        "--rm"
        "-i"
        "mcp/sequentialthinking"
      ];
    };
    "fetch" = {
      "command" = "docker";
      "args" = [
        "run"
        "-i"
        "--rm"
        "mcp/fetch"
      ];
    };
    "nixos" = {
      "command" = "nix";
      "args" = [
        "run"
        "github:utensils/mcp-nixos"
        "--"
      ];
    };
    "time" = {
      "command" = "docker";
      "args" = [
        "run"
        "-i"
        "--rm"
        "mcp/time"
      ];
    };
    "Framelink Figma MCP" = {
      "command" = "npx";
      "args" = [
        "-y"
        "figma-developer-mcp"
        "--figma-api-key=REDACTED_FIGMA_KEY
"
        "--stdio"
      ];
    };
    "playwright" = {
      "command" = "npx";
      "args" = [
        "@playwright/mcp@latest"
      ];
    };
  };
}
