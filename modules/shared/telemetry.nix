{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  cfg = config.telemetry;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
in
{
  options.telemetry = {
    enable = lib.mkEnableOption "local usage telemetry";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = if isLinux then "/var/lib/nix-telemetry" else "\${HOME}/.nix-telemetry";
      description = "Directory to store telemetry data";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "nix-stats" ''
        echo "📊 Nix Statistics"
        echo "Hostname: ${config.networking.hostName or "unknown"}"
        echo "Platform: ${hostSystem}"
        echo "Nix: $(nix --version | awk '{print $3}')"
        echo "Store: $(du -sh /nix/store 2>/dev/null | awk '{print $1}')"
        ${if isLinux then ''
          echo "Generation: $(nixos-rebuild list-generations 2>/dev/null | grep current | awk '{print $1}')"
        '' else ''
          echo "Generation: $(darwin-rebuild --list-generations 2>/dev/null | grep current | awk '{print $1}')"
        ''}
      '')
    ];
  };
}
