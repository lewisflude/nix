# MCP Server Configuration
#
# Simple, declarative MCP server management for AI coding tools.
# Generates JSON configs for Cursor, Claude Code, and other MCP clients.
#
# By default, only servers that don't require secrets are enabled:
# - memory, git, time, sqlite, everything
#
# Servers requiring secrets are disabled by default:
# - docs, openai, rustdocs, github, kagi, brave
#
# Usage:
#   services.mcp.enable = true;  # Enables default servers
#   services.mcp.servers.github.enabled = true;  # Enable server with secret
#
# To use servers with secrets:
#   1. Configure secret in SOPS (secrets/secrets.yaml)
#   2. Enable server in platform config (home/{nixos,darwin}/mcp.nix)
#   3. Rebuild system
{
  config,
  lib,
  pkgs,
  rust-docs-mcp,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    mapAttrs
    filterAttrs
    # optionalAttrs
    ;

  cfg = config.services.mcp;

  # Platform detection
  inherit (pkgs.stdenv) isDarwin;

  # Platform-specific paths
  claudeConfigDir =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/Claude"
    else
      "${config.home.homeDirectory}/.config/claude";

  # Import sub-modules
  serverTypes = import ./types.nix { inherit lib; };
  builders = import ./builders.nix { inherit pkgs lib; };
  defaultServers = import ./servers/default.nix { inherit config pkgs rust-docs-mcp; };

  inherit (serverTypes) serverType;
  inherit (builders) mkServerConfig;

  # Merge user config with defaults (deep merge for each server)
  # User config overrides defaults, and we filter by enabled status
  mergedServers =
    let
      # Helper to filter out null/default values from user config
      filterUserOverrides = userCfg: lib.filterAttrs (_: v: v != null && v != [ ] && v != { }) userCfg;

      # Start with defaults, merge in user overrides (only non-null values)
      mergedDefaults = lib.mapAttrs (
        name: defaultCfg:
        if lib.hasAttr name cfg.servers then
          let
            userOverrides = filterUserOverrides cfg.servers.${name};
          in
          defaultCfg // userOverrides # Merge only non-null user overrides into default
        else
          defaultCfg
      ) defaultServers;
      # Add any user-defined servers not in defaults
      userOnlyServers = lib.filterAttrs (name: _: !(lib.hasAttr name defaultServers)) cfg.servers;
    in
    mergedDefaults // userOnlyServers;

  activeServers = filterAttrs (
    _name: server: (server.enabled or true) # Default to enabled if not specified
  ) mergedServers;

  # Generate the MCP configuration JSON
  mcpConfig = {
    mcpServers = mapAttrs mkServerConfig activeServers;
  };

  configJson = builtins.toJSON mcpConfig;

in
{
  options.services.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) server configuration";

    _generatedServers = mkOption {
      type = types.attrs;
      internal = true;
      description = "Internal option exposing generated MCP server configs for programs.claude-code";
    };

    servers = mkOption {
      type = types.attrsOf serverType;
      default = { };
      description = ''
        MCP servers to configure.

        Enabled by default (no secrets required):
        - memory: Knowledge graph-based persistent memory
        - git: Git repository operations
        - time: Timezone and datetime utilities
        - sqlite: SQLite database access
        - everything: MCP reference/test server

        Disabled by default (require secrets or external dependencies):
        - docs: Documentation indexing (requires OPENAI_API_KEY)
        - openai: OpenAI integration (requires OPENAI_API_KEY)
        - rustdocs: Rust documentation (requires OPENAI_API_KEY)
        - github: GitHub API integration (requires GITHUB_TOKEN)
        - kagi: Kagi search (requires KAGI_API_KEY and uv)
        - brave: Brave Search (requires BRAVE_API_KEY)
        - filesystem: File operations (disabled for security)
        - sequentialthinking: Problem-solving tool (optional)
        - fetch: Web content fetching (optional)
        - nixos: NixOS package search (requires uv)

        To enable servers with secrets, configure the secrets in SOPS first,
        then enable them in your platform-specific config.
      '';
      example = lib.literalExpression ''
        {
          # Enable a server that requires secrets
          github.enabled = true;  # Requires GITHUB_TOKEN in SOPS

          # Override a default server
          docs = {
            enabled = true;
            command = "''${pkgs.nodejs}/bin/npx";
            args = [ "-y" "@arabold/docs-mcp-server@1.32.0" ];
            secret = "OPENAI_API_KEY";
          };

          # Add custom server
          my-server = {
            command = "/path/to/my-server";
            args = [ "--port" "8080" ];
            secret = "MY_API_KEY";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Expose generated servers for programs.claude-code
    services.mcp._generatedServers = mapAttrs mkServerConfig activeServers;

    home = {
      # Install Node.js for NPM-based servers
      packages = [ pkgs.nodejs ];

      # Generate config files
      file = {
        # Cursor configuration
        ".cursor/mcp.json".text = configJson;

        # Claude Desktop App configuration
        "${claudeConfigDir}/claude_desktop_config.json".text = configJson;

        # Note: Claude Code CLI uses programs.claude-code.mcpServers instead
        # See home/common/apps/claude-code.nix

        # Also save to generated directory for reference
        ".mcp-generated/config.json".text = configJson;
      };

      # Activation message
      activation.mcpStatus = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "MCP Configuration Updated"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo
        echo "Active servers:"
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: _server: ''
            echo "  • ${name}"
          '') activeServers
        )}
        echo
        echo "Configuration files:"
        echo "  • Cursor: ~/.cursor/mcp.json"
        echo "  • Claude: ${claudeConfigDir}/claude_desktop_config.json"
        echo
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo
      '';
    };
  };
}
