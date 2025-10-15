# Development feature module (cross-platform)
# Controlled by host.features.development.*
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.development;
in {
  config = mkIf cfg.enable {
    # Environment variables for development
    environment.variables = mkMerge [
      (mkIf cfg.rust {
        RUST_BACKTRACE = "1";
        # CARGO_HOME is managed by rustup
      })
      (mkIf cfg.go {
        GOPATH = "$HOME/go";
        GOBIN = "$HOME/go/bin";
      })
      (mkIf cfg.node {
        NODE_OPTIONS = "--max-old-space-size=4096";
      })
    ];
  };
}
