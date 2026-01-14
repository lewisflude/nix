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
    env = {
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
  };

  # Git operations (no secrets required)
  git = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@cyanheads/git-mcp-server"
    ];
    env = {
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
  };

  # Time and timezone utilities (no secrets required)
  time = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@odgrim/mcp-datetime"
    ];
    env = {
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
  };

  # SQLite database access (no secrets required)
  sqlite = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "mcp-server-sqlite-npx"
      "${config.home.homeDirectory}/.local/share/mcp/data.db"
    ];
    env = {
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
  };

  # MCP reference/test server (no secrets required)
  everything = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-everything"
    ];
    env = {
      NPM_CONFIG_REGISTRY = "https://registry.npmjs.org/";
    };
  };
}
