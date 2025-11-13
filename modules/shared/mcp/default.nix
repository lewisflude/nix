# MCP (Model Context Protocol) Module - Main Entry Point
#
# This module provides cross-platform MCP server configuration for Claude Code and other
# compatible applications. It orchestrates the shared service options, server configurations,
# and wrapper scripts needed to run MCP servers.
#
# Features:
# - Platform-agnostic server definitions
# - Automatic dependency management (uv, Node.js)
# - Integration with shared configuration and secrets
# - Support for both CLI and HTTP-based MCP servers
#
# Usage:
#   services.mcp.enable = true;
#   services.mcp.servers.myserver = { command = "..."; args = [...]; };
#
# See also:
# - ./service.nix: Service option definitions
# - ./servers.nix: Common server configurations
# - ./wrappers.nix: Secret-aware server wrappers
{ pkgs, config, systemConfig, lib, system, ... }:

let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;

  # Import shared servers and utilities
  servers = import ./servers.nix { inherit pkgs config systemConfig lib platformLib; };
  wrappers = import ./wrappers.nix { inherit pkgs systemConfig lib platformLib; };

in {
  imports = [
    ./service.nix
  ];

  config = lib.mkIf config.services.mcp.enable {
    # Install required runtime dependencies
    home.packages = [
      pkgs.uv  # Python package manager for MCP servers
    ] ++ (lib.optionals (servers.nodejs != null) [ servers.nodejs ]);

    # Merge common server configurations
    services.mcp = {
      inherit (servers) commonServers;
    };
  };
}
