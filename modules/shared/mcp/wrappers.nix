# MCP Server Wrapper Scripts
#
# This module provides secure wrapper scripts for MCP servers that require
# secret credentials (API keys, tokens, etc.). Wrappers read secrets from
# SOPS-managed paths and inject them as environment variables.
#
# Architecture:
# - mkSecretWrapper: Generic wrapper builder for SOPS secrets
# - Individual wrappers: Kagi, OpenAI, GitHub, Docs, Rust docs
# - NixOS-specific: rustdocsWrapper with Nix shell integration
#
# Security:
# - Secrets are read at runtime from SOPS paths (not embedded in Nix store)
# - All wrappers use absolute paths for reproducibility
# - Proper error handling with set -euo pipefail
#
# Example:
#   kagiWrapper = mkSecretWrapper {
#     name = "kagi-mcp-wrapper";
#     secretName = "KAGI_API_KEY";
#     command = "exec ${uvx} --from kagimcp kagimcp \"$@\"";
#   };
{ pkgs, systemConfig, lib, platformLib }:

let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    ;

  # Note: nodejs package directly from pkgs (no version wrapper needed)
  uvx = "${pkgs.uv}/bin/uvx";

  # Generic secret wrapper builder
  #
  # Creates a shell wrapper that:
  # 1. Reads a secret from SOPS
  # 2. Exports it as an environment variable
  # 3. Executes the wrapped command
  #
  # Parameters:
  # - name: Name of the wrapper script
  # - secretName: Name of the SOPS secret (must exist in systemConfig.sops.secrets)
  # - command: Command to execute after setting up the environment
  # - extraEnv: Additional environment variables to set (optional)
  mkSecretWrapper = { name, secretName, command, extraEnv ? {} }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        set -euo pipefail

        # Export additional environment variables
        ${concatStringsSep "\n" (mapAttrsToList (k: v:
          ''export ${k}="${v}"''
        ) extraEnv)}

        # Read secret from SOPS and export
        ${secretName}="$(${pkgs.coreutils}/bin/cat ${systemConfig.sops.secrets.${secretName}.path})"
        export ${secretName}

        # Execute wrapped command
        ${command}
      '';
    };

in {
  # Kagi MCP Server Wrapper
  #
  # Wraps the Kagi MCP server with KAGI_API_KEY secret injection.
  # Kagi provides search, summarization, and assistant capabilities.
  #
  # Usage: kagi-mcp-wrapper [args...]
  kagiWrapper = mkSecretWrapper {
    name = "kagi-mcp-wrapper";
    secretName = "KAGI_API_KEY";
    command = ''
      export UV_PYTHON="${pkgs.python3}/bin/python3"
      exec ${uvx} --from kagimcp kagimcp "$@"
    '';
  };

  # OpenAI MCP Server Wrapper
  #
  # Wraps the OpenAI MCP server with OPENAI_API_KEY secret injection.
  # Configures Rust documentation flags for docs.rs compatibility.
  #
  # Environment:
  # - DOCS_RS: Set to 1 for docs.rs mode (defaults to 1)
  # - RUSTDOCFLAGS: Set to "--cfg=docsrs" if not already set
  #
  # Usage: openai-mcp-wrapper [args...]
  openaiWrapper = mkSecretWrapper {
    name = "openai-mcp-wrapper";
    secretName = "OPENAI_API_KEY";
    command = ''
      # Configure Rust documentation mode
      export DOCS_RS="''${DOCS_RS:-1}"
      if [ -z "''${RUSTDOCFLAGS:-}" ]; then
        export RUSTDOCFLAGS="--cfg=docsrs"
      fi

      exec ${nodejs}/bin/npx -y @mzxrai/mcp-openai "$@"
    '';
  };

  # GitHub MCP Server Wrapper
  #
  # Wraps the GitHub MCP server with GITHUB_TOKEN secret injection.
  # Provides GitHub API integration for repositories, issues, PRs, etc.
  #
  # Usage: github-mcp-wrapper [args...]
  githubWrapper = pkgs.writeShellApplication {
    name = "github-mcp-wrapper";
    runtimeInputs = [ pkgs.coreutils nodejs ];
    text = ''
      set -euo pipefail

      # Read GitHub token from SOPS
      GITHUB_TOKEN="$(${pkgs.coreutils}/bin/cat ${systemConfig.sops.secrets.GITHUB_TOKEN.path})"
      export GITHUB_TOKEN

      # Execute GitHub MCP server
      exec ${nodejs}/bin/npx -y @modelcontextprotocol/server-github@latest "$@"
    '';
  };

  # Documentation MCP Server Wrapper
  #
  # Wraps the docs-mcp-server with OPENAI_API_KEY secret injection.
  # Provides documentation search and indexing capabilities.
  #
  # Supports both stdio and HTTP protocols:
  # - stdio: Standard MCP protocol over stdin/stdout
  # - http: HTTP API on specified host/port
  #
  # Usage:
  #   docs-mcp-wrapper                                    # stdio mode
  #   docs-mcp-wrapper --protocol http --port 6280        # HTTP mode
  docsMcpWrapper = mkSecretWrapper {
    name = "docs-mcp-wrapper";
    secretName = "OPENAI_API_KEY";
    command = ''
      exec ${nodejs}/bin/npx -y @arabold/docs-mcp-server@latest "$@"
    '';
  };

  # Rust Documentation MCP Server Wrapper (NixOS only)
  #
  # Wraps the rustdocs-mcp-server with advanced Nix integration.
  # Builds the server on first run and provides cargo documentation support.
  #
  # Features:
  # - Automatic build and caching of rustdocs-mcp-server
  # - Nix shell integration via MCP_NIX_SHELL
  # - Extra package support via MCP_EXTRA_NIX_PKGS
  # - Full OpenSSL and system library configuration
  #
  # Environment Variables:
  # - OPENAI_API_KEY: Required, read from SOPS
  # - MCP_NIX_SHELL: Optional, path to flake for nix develop
  # - MCP_EXTRA_NIX_PKGS: Optional, space-separated list of extra packages
  # - XDG_CACHE_HOME: Used for cache directory (defaults to ~/.cache)
  #
  # Cache Location:
  #   $XDG_CACHE_HOME/mcp/rustdocs-mcp-server
  #
  # Usage:
  #   rustdocs-mcp-wrapper bevy@0.16.1 -F default
  #   MCP_NIX_SHELL="github:bevyengine/bevy" rustdocs-mcp-wrapper
  rustdocsWrapper = pkgs.writeShellApplication {
    name = "rustdocs-mcp-wrapper";
    runtimeInputs = [ pkgs.coreutils pkgs.nix ];
    text = ''
      set -euo pipefail

      # Read OpenAI API key from SOPS
      OPENAI_API_KEY="$(${pkgs.coreutils}/bin/cat ${systemConfig.sops.secrets.OPENAI_API_KEY.path})"
      export OPENAI_API_KEY

      # Set up cache directory
      CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/mcp"
      OUT_LINK="$CACHE_DIR/rustdocs-mcp-server"
      mkdir -p "$CACHE_DIR"

      # Build rustdocs-mcp-server if not cached
      if [ ! -e "$OUT_LINK" ] || [ ! -x "$OUT_LINK/bin/rustdocs_mcp_server" ]; then
        echo "[rustdocs-wrapper] Building rustdocs-mcp-server via nix…"
        ${pkgs.nix}/bin/nix build github:Govcraft/rust-docs-mcp-server --out-link "$OUT_LINK.tmp"
        mv -T "$OUT_LINK.tmp" "$OUT_LINK"
      fi

      # Configure build environment for Rust compilation
      export PKG_CONFIG_PATH="${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.systemd.dev}/lib/pkgconfig:${pkgs.pkg-config}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}"
      export OPENSSL_DIR="${pkgs.openssl.out}"
      export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
      export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      # Run with nix develop if MCP_NIX_SHELL is set
      if [ -n "''${MCP_NIX_SHELL:-}" ]; then
        exec ${pkgs.nix}/bin/nix develop "''${MCP_NIX_SHELL}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
      fi

      # Parse extra packages if specified
      EXTRA_PKGS="''${MCP_EXTRA_NIX_PKGS:-}"
      extra_args=()
      if [ -n "$EXTRA_PKGS" ]; then
        read -r -a extra_args <<< "$EXTRA_PKGS"
      fi

      # Run with nix shell and standard build dependencies
      exec ${pkgs.nix}/bin/nix shell \
        ${pkgs.pkg-config} ${pkgs.alsa-lib} ${pkgs.openssl} ${pkgs.openssl.dev} ${pkgs.cacert} ${pkgs.systemd} ${pkgs.systemd.dev} \
        "''${extra_args[@]}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
    '';
  };
}
