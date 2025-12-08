# MCP Server Configuration
#
# Simple, declarative MCP server management for AI coding tools.
# Generates JSON configs for Cursor, Claude Code, and other MCP clients.
#
# Usage:
#   services.mcp.enable = true;
#   services.mcp.servers.memory = {};
#   services.mcp.servers.docs = { secret = "OPENAI_API_KEY"; };
{
  config,
  lib,
  pkgs,
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
    optionalAttrs
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

  # Simple secret wrapper - one function instead of four builders
  # Secrets are deployed to /run/secrets-for-users/ (with neededForUsers = true)
  # We check at runtime, not build time, so wrappers always work if secret exists
  wrapWithSecret =
    name: cmd: secretName:
    pkgs.writeShellScript "${name}-mcp" ''
      set -euo pipefail

      # Try both possible secret locations
      SECRET_PATH=""
      if [ -r "/run/secrets-for-users/${secretName}" ]; then
        SECRET_PATH="/run/secrets-for-users/${secretName}"
      elif [ -r "/run/secrets/${secretName}" ]; then
        SECRET_PATH="/run/secrets/${secretName}"
      else
        echo "Error: ${name} requires ${secretName} secret" >&2
        echo "Secret not found in /run/secrets-for-users/ or /run/secrets/" >&2
        echo "Configure it in your SOPS secrets and rebuild" >&2
        exit 1
      fi

      export ${secretName}="$(cat "$SECRET_PATH")"
      exec ${cmd} "$@"
    '';

  # Build an MCP server config entry
  mkServerConfig =
    name: serverCfg:
    let
      # Determine the command
      command =
        if (serverCfg.secret or null) != null then
          "${wrapWithSecret name serverCfg.command serverCfg.secret}"
        else
          serverCfg.command;

      # Get args and env with defaults
      args = serverCfg.args or [ ];
      env = serverCfg.env or { };
    in
    {
      inherit command;
    }
    // optionalAttrs (args != [ ]) { inherit args; }
    // optionalAttrs (env != { }) { inherit env; };

  # Server type definition
  serverType = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "Command to run the MCP server";
        example = ''"''${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-memory"'';
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Arguments to pass to the command";
        example = [
          "bevy@0.16.1"
          "-F"
          "default"
        ];
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables to set";
        example = {
          UV_PYTHON = "/nix/store/.../bin/python3";
        };
      };

      secret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Name of SOPS secret to inject (e.g., OPENAI_API_KEY)";
        example = "OPENAI_API_KEY";
      };

      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this server";
      };
    };
  };

  # Build rustdocs server (special case - needs Nix build)
  rustdocsServer =
    let
      inherit (pkgs.stdenv) isLinux isDarwin;

      # Platform-specific build dependencies
      linuxPkgs = lib.optionals isLinux [
        pkgs.alsa-lib
        pkgs.systemd
        pkgs.systemd.dev
      ];

      buildDeps = [
        pkgs.pkg-config
        pkgs.openssl
        pkgs.openssl.dev
        pkgs.cacert
      ]
      ++ linuxPkgs;

      pkgConfigPath =
        if isLinux then
          "${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.systemd.dev}/lib/pkgconfig"
        else
          "${pkgs.openssl.dev}/lib/pkgconfig";

      nixShellPkgs = builtins.concatStringsSep " " (map (p: "${p}") buildDeps);

      rustdocsWrapper = pkgs.writeShellScript "rustdocs-mcp-build" ''
        set -euo pipefail

        # Cache directory
        CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/mcp"
        OUT_LINK="$CACHE_DIR/rustdocs-mcp-server"
        mkdir -p "$CACHE_DIR"

        # Build if not cached
        if [ ! -e "$OUT_LINK" ] || [ ! -x "$OUT_LINK/bin/rustdocs_mcp_server" ]; then
          echo "[mcp] Building rustdocs-mcp-server..." >&2
          ${pkgs.nix}/bin/nix build github:Govcraft/rust-docs-mcp-server --out-link "$OUT_LINK.tmp"
          ${if isDarwin then ''mv "$OUT_LINK.tmp" "$OUT_LINK"'' else ''mv -T "$OUT_LINK.tmp" "$OUT_LINK"''}
        fi

        # Set up build environment
        export PKG_CONFIG_PATH="${pkgConfigPath}:''${PKG_CONFIG_PATH:-}"
        export OPENSSL_DIR="${pkgs.openssl.out}"
        export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
        export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

        # Run in nix shell with build dependencies
        exec ${pkgs.nix}/bin/nix shell ${nixShellPkgs} \
          -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
      '';
    in
    {
      command = "${rustdocsWrapper}";
      args = [
        "bevy@0.16.1"
        "-F"
        "default"
      ];
      secret = "OPENAI_API_KEY";
    };

  # Default server configurations
  defaultServers = {
    # Memory - knowledge graph-based persistent memory
    memory = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
    };

    # Documentation indexing and search
    docs = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@arabold/docs-mcp-server"
      ];
      secret = "OPENAI_API_KEY";
    };

    # OpenAI integration
    openai = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@mzxrai/mcp-openai"
      ];
      secret = "OPENAI_API_KEY";
      env = {
        DOCS_RS = "1";
        RUSTDOCFLAGS = "--cfg=docsrs";
      };
    };

    # Rust documentation (Bevy)
    rustdocs = rustdocsServer;

    # Git operations
    git = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@cyanheads/git-mcp-server"
      ];
    };

    # Time and timezone utilities
    time = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@odgrim/mcp-datetime"
      ];
    };

    # SQLite database access
    sqlite = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "mcp-server-sqlite-npx"
        "${config.home.homeDirectory}/.local/share/mcp/data.db"
      ];
    };

    # GitHub API integration
    github = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@cyanheads/github-mcp-server"
      ];
      secret = "GITHUB_TOKEN";
    };

    # MCP reference/test server
    everything = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-everything"
      ];
    };

    # Web content fetching and conversion for efficient LLM usage
    # Note: Official @modelcontextprotocol/server-fetch not yet published
    fetch = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "mcp-server-fetch-typescript"
      ];
      enabled = false; # Disabled - using community alternative, enable if needed
    };

    # Secure file operations with configurable access controls
    # Note: Configure allowed directories in your platform-specific config
    filesystem = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        config.home.homeDirectory
      ];
    };

    # Dynamic and reflective problem-solving through thought sequences
    sequentialthinking = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
    };

    # Kagi search - Still broken (uv package not fixed)
    kagi = {
      command = "${pkgs.uv}/bin/uvx";
      args = [ "mcp-server-kagi" ];
      secret = "KAGI_API_KEY";
      enabled = false; # Disabled - uv package still not available
    };

    # Brave Search - Fallback if Kagi doesn't work
    brave = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@brave/brave-search-mcp-server"
      ];
      secret = "BRAVE_API_KEY";
      enabled = false; # Disabled - Kagi is preferred
    };

    # NixOS package search (requires uv)
    nixos = {
      command = "${pkgs.uv}/bin/uvx";
      args = [ "mcp-nixos" ];
      enabled = false; # Disabled until uv is fixed
    };
  };

  # Merge user config with defaults
  # User config overrides defaults, and we filter by enabled status
  mergedServers = defaultServers // cfg.servers;
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

    servers = mkOption {
      type = types.attrsOf serverType;
      default = { };
      description = ''
        MCP servers to configure.

        Defaults include: memory, docs, openai, rustdocs, git, time, sqlite, github, everything.
        Disabled by default: kagi, nixos (require broken uv package).

        You can override defaults or add new servers.
      '';
      example = lib.literalExpression ''
        {
          # Use default memory server
          memory = {};

          # Override docs server
          docs = {
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
    home = {
      # Install Node.js for NPM-based servers
      packages = [ pkgs.nodejs ];

      # Generate config files
      file = {
        # Cursor configuration
        ".cursor/mcp.json".text = configJson;

        # Claude Code configuration
        "${claudeConfigDir}/claude_desktop_config.json".text = configJson;

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
