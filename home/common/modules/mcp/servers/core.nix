# Core MCP Servers (enabled by default, no secrets required)
{
  config,
  pkgs,
  ...
}:
{
  # Memory - knowledge graph-based persistent memory (no secrets required)
  memory = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-memory"
    ];
  };

  # Git operations (no secrets required)
  git = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@cyanheads/git-mcp-server"
    ];
  };

  # Time and timezone utilities (no secrets required)
  time = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@odgrim/mcp-datetime"
    ];
  };

  # SQLite database access (no secrets required)
  sqlite = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "mcp-server-sqlite-npx"
      "${config.home.homeDirectory}/.local/share/mcp/data.db"
    ];
  };

  # MCP reference/test server (no secrets required)
  everything = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-everything"
    ];
  };
}
