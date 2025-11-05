{
  lib,
  host,
  ...
}:
let
  cfg = host.features.development;
in
{
  # Note: git, gh, curl, wget, jq, yq are provided by home/common/apps/core-tooling.nix
  # This module is kept for future version control specific configurations
  config = lib.mkIf cfg.enable {
    # Version control configurations go here
  };
}
