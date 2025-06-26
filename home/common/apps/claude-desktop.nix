{ pkgs, mcp-servers-nix, ... }:
let
  mcp-lib = (import mcp-servers-nix { inherit pkgs; }).lib;
  
  mcpPrograms = {
    filesystem = {
      enable = true;
      args = [ "/Users/lewisflude" ];
    };
    fetch = {
      enable = true;
    };
    git = {
      enable = true;
    };
    github = {
      enable = true;
      envFile = "/Users/lewisflude/.config/github-token";
    };
    sqlite = {
      enable = true;
    };
  };

  claude-config = mcp-lib.mkConfig pkgs {
    flavor = "claude";
    programs = mcpPrograms;
  };
in
{
  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    text = builtins.toJSON claude-config;
  };
}