{
  lib,
  host,
  pkgs,
  ...
}: let
  cfg = host.features.development;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      git
      gh
      curl
      wget
      jq
      yq
    ];
  };
}
