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
{
  pkgs,
  systemConfig,
  lib,
}:

let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    ;

  # Note: nodejs package directly from pkgs (no version wrapper needed)
  # TEMPORARILY DISABLED: uv build failing
  # uvx = "${pkgs.uv}/bin/uvx";

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
  mkSecretWrapper =
    {
      name,
      secretName,
      command,
      extraEnv ? { },
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        set -euo pipefail

        # Export additional environment variables
        ${concatStringsSep "\n" (mapAttrsToList (k: v: ''export ${k}="${v}"'') extraEnv)}

        # Read secret from SOPS and export
        ${secretName}="$(${pkgs.coreutils}/bin/cat ${systemConfig.sops.secrets.${secretName}.path})"
        export ${secretName}

        # Execute wrapped command
        ${command}
      '';
    };

in
{
  # Kagi MCP Server Wrapper
  #
  # Wraps the Kagi MCP server with KAGI_API_KEY secret injection.
  # Kagi provides search, summarization, and assistant capabilities.
  #
  # Usage: kagi-mcp-wrapper [args...]
  # TEMPORARILY DISABLED: uv build failing
  kagiWrapper = pkgs.writeShellApplication {
    name = "kagi-mcp-wrapper";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -euo pipefail
      echo "Kagi MCP server temporarily disabled due to uv build failure" >&2
      exit 1
    '';
  };

  # kagiWrapper = mkSecretWrapper {
  #   name = "kagi-mcp-wrapper";
  #   secretName = "KAGI_API_KEY";
  #   command = ''
  #     export UV_PYTHON="${pkgs.python3}/bin/python3"
  #     exec ${uvx} --from kagimcp==0.2.0 kagimcp "$@"
  #   '';
  # };

  # OpenAI MCP server with Rust documentation support
  openaiWrapper = mkSecretWrapper {
    name = "openai-mcp-wrapper";
    secretName = "OPENAI_API_KEY";
    command = ''
      # Configure Rust documentation mode
      export DOCS_RS="''${DOCS_RS:-1}"
      if [ -z "''${RUSTDOCFLAGS:-}" ]; then
        export RUSTDOCFLAGS="--cfg=docsrs"
      fi

      exec ${pkgs.nodejs}/bin/npx -y @mzxrai/mcp-openai "$@"
    '';
  };

  # Documentation MCP server (supports stdio and HTTP protocols)
  docsMcpWrapper = mkSecretWrapper {
    name = "docs-mcp-wrapper";
    secretName = "OPENAI_API_KEY";
    command = ''
      exec ${pkgs.nodejs}/bin/npx -y @arabold/docs-mcp-server@0.3.1 "$@"
    '';
  };

  # Rust documentation MCP server with Nix shell integration
  # Supports MCP_NIX_SHELL and MCP_EXTRA_NIX_PKGS environment variables
  rustdocsWrapper = pkgs.writeShellApplication {
    name = "rustdocs-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nix
    ];
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
