# MCP Server Wrapper Scripts - Enterprise Architecture
#
# This module provides a robust, maintainable system for creating secure
# wrapper scripts for MCP servers that require credentials or special runtime
# environments.
#
# Architecture:
# - Builder Pattern: Generic wrapper builders for different use cases
# - Dependency Injection: Runtime dependencies specified explicitly
# - Feature Detection: Automatic availability checking
# - Error Handling: Graceful degradation with clear error messages
# - Security: Secrets loaded at runtime from SOPS paths
#
# Builders:
# - mkSecretWrapper: Wrapper with SOPS secret injection
# - mkSimpleWrapper: Wrapper without secrets (for public servers)
# - mkDisabledWrapper: Stub for unavailable servers with clear error messages
# - mkNpxWrapper: Specialized wrapper for npx-based Node.js servers
#
# Health Checks:
# Each wrapper includes health check capability via --health-check flag
#
# Usage:
#   wrappers = import ./wrappers.nix {
#     inherit pkgs lib;
#     systemConfig = osConfig; # or systemConfig on Darwin
#   };
#
#   # Use in configuration
#   home.packages = [ wrappers.docsMcpWrapper ];
{
  pkgs,
  systemConfig,
  lib,
}:

let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    optionalString
    ;

  # Common runtime inputs for all wrappers
  commonRuntimeInputs = [
    pkgs.coreutils
    pkgs.gawk
    pkgs.gnugrep
  ];

  # Logging utilities for consistent output
  logInfo = msg: ''echo "[mcp-wrapper] INFO: ${msg}" >&2'';
  logWarn = msg: ''echo "[mcp-wrapper] WARN: ${msg}" >&2'';
  logError = msg: ''echo "[mcp-wrapper] ERROR: ${msg}" >&2'';

  #
  # Builder: Secret-Aware Wrapper
  #
  # Creates a wrapper that injects SOPS secrets as environment variables
  # before executing the target command.
  #
  # Parameters:
  #   - name: Wrapper script name (e.g., "kagi-mcp-wrapper")
  #   - secretName: SOPS secret key (must exist in systemConfig.sops.secrets)
  #   - command: Command to execute after secret injection
  #   - extraEnv: Additional environment variables (default: {})
  #   - runtimeInputs: Additional packages for PATH (default: [])
  #   - healthCheck: Health check command (default: null)
  #
  # Returns: Derivation containing the wrapper script
  #
  mkSecretWrapper =
    {
      name,
      secretName,
      command,
      extraEnv ? { },
      runtimeInputs ? [ ],
      healthCheck ? null,
    }:
    let
      secretPath = systemConfig.sops.secrets.${secretName}.path or null;
      hasSecret = secretPath != null;
    in
    if !hasSecret then
      mkDisabledWrapper {
        inherit name;
        reason = "SOPS secret '${secretName}' not configured";
        suggestion = "Add secret to systemConfig.sops.secrets.${secretName}";
      }
    else
      pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = commonRuntimeInputs ++ runtimeInputs;
        text = ''
          set -euo pipefail

          # Health check mode
          ${optionalString (healthCheck != null) ''
            if [ "''${1:-}" = "--health-check" ]; then
              ${logInfo "Running health check for ${name}"}
              ${healthCheck}
              # Health check passed (set -e would exit on failure)
              # shellcheck disable=SC2317
              exit 0
            fi
          ''}

          # Export additional environment variables
          ${concatStringsSep "\n" (mapAttrsToList (k: v: ''export ${k}="${v}"'') extraEnv)}

          # Read and export secret from SOPS
          if [ ! -r "${secretPath}" ]; then
            ${logError "Cannot read secret at ${secretPath}"}
            exit 1
          fi

          ${secretName}="$(<"${secretPath}")"
          export ${secretName}

          # Execute target command
          ${logInfo "Starting MCP server: ${name}"}
          ${command}
        '';
      };

  #
  # Builder: Simple Wrapper (No Secrets)
  #
  # Creates a wrapper for servers that don't require secrets.
  # Useful for public MCP servers or those using only environment config.
  #
  # Parameters:
  #   - name: Wrapper script name
  #   - command: Command to execute
  #   - env: Environment variables (default: {})
  #   - runtimeInputs: Additional packages for PATH (default: [])
  #   - healthCheck: Health check command (default: null)
  #
  # Returns: Derivation containing the wrapper script
  #
  mkSimpleWrapper =
    {
      name,
      command,
      env ? { },
      runtimeInputs ? [ ],
      healthCheck ? null,
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = commonRuntimeInputs ++ runtimeInputs;
      text = ''
        set -euo pipefail

        # Health check mode
        ${optionalString (healthCheck != null) ''
          if [ "''${1:-}" = "--health-check" ]; then
            ${logInfo "Running health check for ${name}"}
            ${healthCheck}
            # Health check passed (set -e would exit on failure)
            exit 0
          fi
        ''}

        # Export environment variables
        ${concatStringsSep "\n" (mapAttrsToList (k: v: ''export ${k}="${v}"'') env)}

        # Execute target command
        ${logInfo "Starting MCP server: ${name}"}
        ${command}
      '';
    };

  #
  # Builder: Disabled Wrapper (Unavailable Server)
  #
  # Creates a stub wrapper that explains why a server is unavailable
  # and provides actionable suggestions for enabling it.
  #
  # Parameters:
  #   - name: Wrapper script name
  #   - reason: Why the server is disabled
  #   - suggestion: How to enable it (optional)
  #
  # Returns: Derivation containing a stub script
  #
  mkDisabledWrapper =
    {
      name,
      reason,
      suggestion ? null,
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = commonRuntimeInputs;
      text = ''
        set -euo pipefail

        ${logError "MCP server '${name}' is disabled"}
        ${logError "Reason: ${reason}"}
        ${optionalString (suggestion != null) ''
          ${logInfo "To enable: ${suggestion}"}
        ''}

        exit 1
      '';
    };

  #
  # Builder: NPX Wrapper
  #
  # Specialized wrapper for Node.js packages installed via npx.
  # Handles version pinning and caching automatically.
  #
  # Parameters:
  #   - name: Wrapper script name
  #   - package: NPM package (e.g., "@modelcontextprotocol/server-memory@0.1.0")
  #   - secretName: Optional SOPS secret to inject
  #   - extraEnv: Additional environment variables (default: {})
  #   - healthCheck: Health check command (default: null)
  #
  # Returns: Derivation containing the wrapper script
  #
  mkNpxWrapper =
    {
      name,
      package,
      secretName ? null,
      extraEnv ? { },
      healthCheck ? null,
    }:
    let
      hasSecret = secretName != null;
      secretPath = if hasSecret then systemConfig.sops.secrets.${secretName}.path or null else null;
      secretAvailable = !hasSecret || secretPath != null;
    in
    if !secretAvailable then
      mkDisabledWrapper {
        inherit name;
        reason = "SOPS secret '${secretName}' not configured";
        suggestion = "Add secret to systemConfig.sops.secrets.${secretName}";
      }
    else
      pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = commonRuntimeInputs ++ [ pkgs.nodejs ];
        text = ''
          set -euo pipefail

          # Health check mode
          ${optionalString (healthCheck != null) ''
            if [ "''${1:-}" = "--health-check" ]; then
              ${logInfo "Running health check for ${name}"}
              ${healthCheck}
              # Health check passed (set -e would exit on failure)
              # shellcheck disable=SC2317
              exit 0
            fi
          ''}

          # Export additional environment variables
          ${concatStringsSep "\n" (mapAttrsToList (k: v: ''export ${k}="${v}"'') extraEnv)}

          # Read and export secret if required
          ${optionalString hasSecret ''
            if [ ! -r "${secretPath}" ]; then
              ${logError "Cannot read secret at ${secretPath}"}
              exit 1
            fi

            ${secretName}="$(<"${secretPath}")"
            export ${secretName}
          ''}

          # Execute npx command
          ${logInfo "Starting NPX MCP server: ${package}"}
          exec ${pkgs.nodejs}/bin/npx -y ${package} "$@"
        '';
      };

in
{
  # Export builders for use in MCP configurations
  inherit
    mkSecretWrapper
    mkSimpleWrapper
    mkDisabledWrapper
    mkNpxWrapper
    ;

  #
  # Pre-built Wrappers
  #
  # These are ready-to-use wrappers for common MCP servers.
  # Each wrapper includes health check support via --health-check flag.
  #

  # Memory Server - Knowledge graph-based persistent memory
  # No secrets required, pure Node.js implementation
  memoryWrapper = mkNpxWrapper {
    name = "memory-mcp-wrapper";
    package = "@modelcontextprotocol/server-memory@0.1.0";
    healthCheck = ''
      ${logInfo "Memory server has no health check endpoint"}
      exit 0
    '';
  };

  # Documentation MCP Server - Documentation indexing and search
  # Requires OpenAI API key for vector search (optional for basic features)
  docsMcpWrapper = mkNpxWrapper {
    name = "docs-mcp-wrapper";
    package = "@arabold/docs-mcp-server@0.3.1";
    secretName = "OPENAI_API_KEY";
    healthCheck = ''
      ${logInfo "Docs server health check not implemented yet"}
      exit 0
    '';
  };

  # OpenAI MCP Server - General OpenAI integration
  # Requires OpenAI API key, supports Rust documentation mode
  openaiWrapper = mkNpxWrapper {
    name = "openai-mcp-wrapper";
    package = "@mzxrai/mcp-openai";
    secretName = "OPENAI_API_KEY";
    extraEnv = {
      DOCS_RS = "1";
      RUSTDOCFLAGS = "--cfg=docsrs";
    };
    healthCheck = ''
      if [ -z "''${OPENAI_API_KEY:-}" ]; then
        ${logError "OPENAI_API_KEY not set"}
        exit 1
      fi
      exit 0
    '';
  };

  # Kagi MCP Server - Search and summarization
  # DISABLED: Requires uv package which is currently failing to build
  kagiWrapper = mkDisabledWrapper {
    name = "kagi-mcp-wrapper";
    reason = "Depends on 'uv' package which is currently unavailable in nixpkgs";
    suggestion = "Wait for uv build to be fixed, or use alternative search server";
  };

  # NixOS MCP Server - NixOS package and configuration search
  # DISABLED: Requires uv package which is currently failing to build
  nixosWrapper = mkDisabledWrapper {
    name = "nixos-mcp-wrapper";
    reason = "Depends on 'uv' package which is currently unavailable in nixpkgs";
    suggestion = "Wait for uv build to be fixed, or contribute a Node.js alternative";
  };

  # Rust Documentation MCP Server - Bevy and other crate documentation
  # Requires OpenAI API key and Nix for building Rust docs
  # Platform-aware: Uses different build dependencies on Linux vs Darwin
  rustdocsWrapper =
    let
      isLinux = pkgs.stdenv.isLinux;
      isDarwin = pkgs.stdenv.isDarwin;

      # Platform-specific packages
      linuxPkgs = lib.optionals isLinux [
        pkgs.alsa-lib
        pkgs.systemd
        pkgs.systemd.dev
      ];

      # Build dependencies needed for running rustdocs-mcp-server
      buildDeps = [
        pkgs.pkg-config
        pkgs.openssl
        pkgs.openssl.dev
        pkgs.cacert
      ]
      ++ linuxPkgs;

      # PKG_CONFIG_PATH for Linux (with ALSA and systemd)
      linuxPkgConfigPath = "${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.systemd.dev}/lib/pkgconfig:${pkgs.pkg-config}/lib/pkgconfig";

      # PKG_CONFIG_PATH for Darwin (without Linux-specific libraries)
      darwinPkgConfigPath = "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.pkg-config}/lib/pkgconfig";

      pkgConfigPath = if isLinux then linuxPkgConfigPath else darwinPkgConfigPath;

      # Nix shell packages as string for command line
      nixShellPkgs = builtins.concatStringsSep " " (map (p: "${p}") buildDeps);
    in
    mkSecretWrapper {
      name = "rustdocs-mcp-wrapper";
      secretName = "OPENAI_API_KEY";
      runtimeInputs = [ pkgs.nix ];
      command = ''
        # Set up cache directory
        CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/mcp"
        OUT_LINK="$CACHE_DIR/rustdocs-mcp-server"
        mkdir -p "$CACHE_DIR"

        # Build rustdocs-mcp-server if not cached
        if [ ! -e "$OUT_LINK" ] || [ ! -x "$OUT_LINK/bin/rustdocs_mcp_server" ]; then
          ${logInfo "Building rustdocs-mcp-server from GitHub..."}
          ${pkgs.nix}/bin/nix build github:Govcraft/rust-docs-mcp-server --out-link "$OUT_LINK.tmp"
          ${if isDarwin then ''mv "$OUT_LINK.tmp" "$OUT_LINK"'' else ''mv -T "$OUT_LINK.tmp" "$OUT_LINK"''}
        fi

        # Configure Rust build environment
        export PKG_CONFIG_PATH="${pkgConfigPath}:''${PKG_CONFIG_PATH:-}"
        export OPENSSL_DIR="${pkgs.openssl.out}"
        export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
        export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

        # Support custom Nix shell environments
        if [ -n "''${MCP_NIX_SHELL:-}" ]; then
          ${logInfo "Running in nix develop shell: $MCP_NIX_SHELL"}
          exec ${pkgs.nix}/bin/nix develop "''${MCP_NIX_SHELL}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
        fi

        # Parse extra packages for nix shell
        EXTRA_PKGS="''${MCP_EXTRA_NIX_PKGS:-}"
        extra_args=()
        if [ -n "$EXTRA_PKGS" ]; then
          read -r -a extra_args <<< "$EXTRA_PKGS"
        fi

        # Run with standard build dependencies
        exec ${pkgs.nix}/bin/nix shell ${nixShellPkgs} "''${extra_args[@]}" \
          -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
      '';
      healthCheck = ''
        if [ -z "''${OPENAI_API_KEY:-}" ]; then
          ${logError "OPENAI_API_KEY not set"}
          exit 1
        fi

        CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/mcp"
        OUT_LINK="$CACHE_DIR/rustdocs-mcp-server"

        if [ ! -e "$OUT_LINK/bin/rustdocs_mcp_server" ]; then
          ${logError "rustdocs-mcp-server not built"}
          exit 1
        fi

        exit 0
      '';
    };
}
