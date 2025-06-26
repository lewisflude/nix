{ mcpConfigs ? null, ... }:
{
  # Claude Desktop MCP configuration
  home.file."Library/Application Support/Claude/claude_desktop_config.json" = 
    if mcpConfigs != null then {
      text = builtins.toJSON mcpConfigs.claude;
    } else {
      text = "{}";
    };
}