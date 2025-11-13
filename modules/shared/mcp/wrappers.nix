{ pkgs, systemConfig, lib, platformLib }:

let
  nodejs = platformLib.getVersionedPackage pkgs platformLib.versions.nodejs;
  uvx = "${pkgs.uv}/bin/uvx";

  # Helper function to create a wrapper that reads a SOPS secret
  mkSecretWrapper = { name, secretName, command, extraEnv ? {} }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        set -euo pipefail
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v:
          ''export ${k}="${v}"''
        ) extraEnv)}
        ${secretName}="$(${pkgs.coreutils}/bin/cat ${systemConfig.sops.secrets.${secretName}.path})"
        export ${secretName}
        ${command}
      '';
    };

in {
  # Kagi MCP wrapper
  kagiWrapper = mkSecretWrapper {
    name = "kagi-mcp-wrapper";
    secretName = "KAGI_API_KEY";
    command = ''
      export UV_PYTHON="${pkgs.python3}/bin/python3"
      exec ${uvx} --from kagimcp kagimcp "$@"
    '';
  };

  # OpenAI MCP wrapper
  openaiWrapper = mkSecretWrapper {
    name = "openai-mcp-wrapper";
    secretName = "OPENAI_API_KEY";
    command = ''
      export DOCS_RS="''${DOCS_RS:-1}"
      if [ -z "''${RUSTDOCFLAGS:-}" ]; then
        export RUSTDOCFLAGS="--cfg=docsrs"
      fi
      exec ${nodejs}/bin/npx -y @mzxrai/mcp-openai "$@"
    '';
  };

  # GitHub MCP wrapper
  githubWrapper = pkgs.writeShellApplication {
    name = "github-mcp-wrapper";
    runtimeInputs = [ pkgs.coreutils nodejs ];
    text = ''
      set -euo pipefail
      GITHUB_TOKEN="$(${pkgs.coreutils}/bin/cat ${systemConfig.sops.secrets.GITHUB_TOKEN.path})"
      export GITHUB_TOKEN
      exec ${nodejs}/bin/npx -y @modelcontextprotocol/server-github@latest "$@"
    '';
  };

  # Docs MCP wrapper
  docsMcpWrapper = mkSecretWrapper {
    name = "docs-mcp-wrapper";
    secretName = "OPENAI_API_KEY";
    command = ''
      exec ${nodejs}/bin/npx -y @arabold/docs-mcp-server@latest "$@"
    '';
  };

  # Rust docs MCP wrapper (NixOS only)
  rustdocsWrapper = pkgs.writeShellApplication {
    name = "rustdocs-mcp-wrapper";
    runtimeInputs = [ pkgs.coreutils pkgs.nix ];
    text = ''
      set -euo pipefail
      OPENAI_API_KEY="$(${pkgs.coreutils}/bin/cat ${systemConfig.sops.secrets.OPENAI_API_KEY.path})"
      export OPENAI_API_KEY
      CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/mcp"
      OUT_LINK="$CACHE_DIR/rustdocs-mcp-server"
      mkdir -p "$CACHE_DIR"
      if [ ! -e "$OUT_LINK" ] || [ ! -x "$OUT_LINK/bin/rustdocs_mcp_server" ]; then
        echo "[rustdocs-wrapper] Building rustdocs-mcp-server via nix…"
        ${pkgs.nix}/bin/nix build github:Govcraft/rust-docs-mcp-server
        mv -T "$OUT_LINK.tmp" "$OUT_LINK"
      fi
      export PKG_CONFIG_PATH="${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.systemd.dev}/lib/pkgconfig:${pkgs.pkg-config}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}"
      export OPENSSL_DIR="${pkgs.openssl.out}"
      export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
      export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      if [ -n "''${MCP_NIX_SHELL:-}" ]; then
        exec ${pkgs.nix}/bin/nix develop "''${MCP_NIX_SHELL}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
      fi
      EXTRA_PKGS="''${MCP_EXTRA_NIX_PKGS:-}"
      extra_args=()
      if [ -n "$EXTRA_PKGS" ]; then
        read -r -a extra_args <<< "$EXTRA_PKGS"
      fi
      exec ${pkgs.nix}/bin/nix shell \
        ${pkgs.pkg-config} ${pkgs.alsa-lib} ${pkgs.openssl} ${pkgs.openssl.dev} ${pkgs.cacert} ${pkgs.systemd} ${pkgs.systemd.dev} \
        "''${extra_args[@]}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
    '';
  };
}
