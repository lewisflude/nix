{ pkgs, config, systemConfig, lib, platformLib }:

let
  uvx = "${pkgs.uv}/bin/uvx";
  nodejs = platformLib.getVersionedPackage pkgs platformLib.versions.nodejs;
  codeDirectory = "${config.home.homeDirectory}/Code";

  # Common MCP server ports
  ports = {
    kagi = 11431;
    fetch = 11432;
    git = 11433;
    github = 11434;
    memory = 11436;
    sequential-thinking-darwin = 11438;
    sequential-thinking-nixos = 11437;
    openai = 11439;
    rust-docs = 11440;
    nixos = 11441;
    general-filesystem = 11442;
    time-darwin = 11443;
    time-nixos = 11445;
    docs = 6280;
  };

in {
  inherit nodejs ports;

  # Common server configurations that can be used across platforms
  commonServers = {
    fetch = {
      command = uvx;
      args = [
        "--from"
        "mcp-server-fetch"
        "mcp-server-fetch"
      ];
      port = ports.fetch;
      env = {
        UV_PYTHON = "${pkgs.python3}/bin/python3";
      };
    };

    memory = {
      command = "${nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory@latest"
      ];
      port = ports.memory;
    };

    general-filesystem = {
      command = "${nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem@latest"
        codeDirectory
        "${config.home.homeDirectory}/.config"
        "${config.home.homeDirectory}/Documents"
      ];
      port = ports.general-filesystem;
    };

    nixos = {
      command = uvx;
      args = [
        "--from"
        "mcp-nixos"
        "mcp-nixos"
      ];
      port = ports.nixos;
      env = {
        UV_PYTHON = "${pkgs.python3}/bin/python3";
      };
    };

    git = {
      command = uvx;
      args = [
        "--from"
        "mcp-server-git"
        "mcp-server-git"
        "--repository"
        "${codeDirectory}/dex-web"
      ];
      port = ports.git;
      env = {
        UV_PYTHON = "${pkgs.python3}/bin/python3";
      };
    };
  };
}
