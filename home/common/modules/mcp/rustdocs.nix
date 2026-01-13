# Rustdocs MCP Server Builder
# Special case - needs Nix build with platform-specific dependencies
{
  pkgs,
  lib,
}:
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
  rustdocsServer = {
    command = "${rustdocsWrapper}";
    args = [
      "bevy@0.16.1"
      "-F"
      "default"
    ];
    secret = "OPENAI_API_KEY";
  };
}
