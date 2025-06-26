{ pkgs, mcpConfigs, ... }:
{
  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    text = builtins.toJSON mcpConfigs.claude;
  };
}