{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    uv
  ];

  home.file."bin/kagi-mcp-wrapper".text = ''
    #!/usr/bin/env bash
    export KAGI_API_KEY="$(cat ${config.sops.secrets.KAGI_API_KEY.path})"
    exec ${pkgs.uv}/bin/uvx kagimcp "$@"
  '';
  home.file."bin/kagi-mcp-wrapper".executable = true;

  services.mcp.enable = true;
  services.mcp.targets = {
    cursor = {
      directory = "${config.home.homeDirectory}/.cursor";
      fileName = "mcp.json";
    };
    claude = {
      directory = "/Users/${config.home.username}/Library/Application Support/Claude";
      fileName = "claude_desktop_config.json";
    };
  };
  services.mcp.servers = {
    kagi = {
      command = "${config.home.homeDirectory}/bin/kagi-mcp-wrapper";
      args = [ ];
      port = 11431;
      env = {
        KAGI_API_KEY = config.sops.secrets.KAGI_API_KEY.path;
      };
    };
    fetch = {
      command = "${pkgs.uv}/bin/uvx";
      args = [ "mcp-server-fetch" ];
      port = 11432;
    };

    nx = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "nx-mcp@latest"
        "/Users/lewisflude/Code/dex-web"
      ];
      port = 11437;
    };
    sequential-thinking = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
      port = 11438;
    };
    github = {
      command = "${pkgs.docker}/bin/docker";
      args = [
        "run"
        "-i"
        "--rm"
        "-e"
        "GITHUB_PERSONAL_ACCESS_TOKEN"
        "ghcr.io/github/github-mcp-server"
      ];
      env = {
        GITHUB_PERSONAL_ACCESS_TOKEN = config.sops.secrets.GITHUB_PERSONAL_ACCESS_TOKEN.path;
      };
    };
    filesystem = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        "${config.home.homeDirectory}"
        "${config.home.homeDirectory}/.config"

      ];
      port = 11439;
    };
    mcp-obsidian = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "mcp-obsidian"
      ];
      env = {
        OBSIDIAN_API_KEY = config.sops.secrets.OBSIDIAN_API_KEY.path;
        OBSIDIAN_HOST = "127.0.0.1";
        OBSIDIAN_PORT = "27124";
      };
    };
  };
}
