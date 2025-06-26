{ pkgs, inputs, ... }:
let
  mcp-servers = import inputs.mcp-servers-nix { inherit pkgs; };
  mcp-lib = mcp-servers.lib;

  mcpPrograms = {
    filesystem = {
      enable = true;
      args = [
        "/Users/lewisflude/Documents"
        "/Users/lewisflude/Downloads"
        "/Users/lewisflude/Desktop"
        "/Users/lewisflude/Projects"
        "/Users/lewisflude/Code"
      ];
    };
    fetch = {
      enable = false;
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
    slack = {
      enable = true;
      envFile = "/Users/lewisflude/.config/slack-token";
    };
    notion = {
      enable = true;
      envFile = "/Users/lewisflude/.config/notion-token";
    };
    playwright = {
      enable = true;
    };
    postgres = {
      enable = true;
      envFile = "/Users/lewisflude/.config/postgres.env";
    };
    redis = {
      enable = true;
      envFile = "/Users/lewisflude/.config/redis.env";
    };
    sequential-thinking = {
      enable = true;
    };
    memory = {
      enable = true;
    };
  };

  claude-config = mcp-lib.mkConfig pkgs {
    flavor = "claude";
    programs = mcpPrograms;
  };

  cursor-config = mcp-lib.mkConfig pkgs {
    fileName = "settings.json";
    flavor = "vscode";
    programs = mcpPrograms;
  };

  cursor-with-mcp = pkgs.writeShellScriptBin "cursor-with-mcp" ''
    dir="/tmp/mcp-servers-nix-cursor"
    ${pkgs.coreutils}/bin/mkdir -p "$dir/User"
    cat ${cursor-config} > "$dir/User/settings.json"
    ${pkgs.lib.getExe pkgs.code-cursor} --user-data-dir "$dir" "$@"
  '';
in
{
  config = {
    environment.systemPackages = 
      let
        enabledPackages = builtins.filter (pkg: 
          let
            name = pkg.pname or (builtins.parseDrvName pkg.name).name;
            programName = if builtins.hasAttr name mcpPrograms 
                         then name 
                         else if name == "mcp-server-fetch" then "fetch"
                         else name;
          in
          builtins.hasAttr programName mcpPrograms && mcpPrograms.${programName}.enable or false
        ) (builtins.attrValues mcp-servers.packages);
      in
      enabledPackages ++ [ cursor-with-mcp ];

    # Keep cursor config in system for backward compatibility with existing setup
    environment.etc."cursor_mcp_config.json" = {
      text = builtins.toJSON cursor-config;
    };

    # Export MCP configurations for home-manager use
    _module.args.mcpConfigs = {
      claude = claude-config;
      cursor = cursor-config;
    };
  };
}
