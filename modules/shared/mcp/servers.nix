# Common MCP Server Definitions
#
# This module provides pre-configured MCP server definitions that are shared
# across NixOS and nix-darwin platforms. Servers are defined with proper paths,
# arguments, and port allocations from centralized constants.
#
# Architecture:
# - commonServers: Attribute set of ready-to-use server configurations
# - ports: Centralized port assignments from lib/constants.nix
# - nodejs: Platform-specific Node.js version
#
# Included Servers:
# - fetch: HTTP fetching and web scraping
# - memory: Persistent memory and context management
# - general-filesystem: File system operations
# - nixos: NixOS configuration management
# - git: Git repository operations
#
# Usage:
#   servers = import ./servers.nix { inherit pkgs config systemConfig lib platformLib; };
#   services.mcp.servers = servers.commonServers // { custom-server = {...}; };
{ pkgs, config, systemConfig, lib, platformLib }:

let
  # Import centralized constants
  constants = import ../../../lib/constants.nix;

  uvx = "${pkgs.uv}/bin/uvx";
  nodejs = pkgs.nodejs;
  codeDirectory = "${config.home.homeDirectory}/Code";

  # Use ports from constants for consistency
  ports = constants.ports.mcp;

in {
  # Export Node.js and ports for use by consumers
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
      port = ports.filesystem;
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
