{
  # config,
  lib,
  pkgs,
  # qbittorrentCfg,
  webUI,
  ...
}:
with lib;
let
  # Build WebUI config cleanly
  webUICfg =
    if webUI != null then
      mkMerge [
        {
          Address = webUI.bindAddress;
          Port = webUI.port;
          HostHeaderValidation = false;
          LocalHostAuth = false;
          AlternativeUIEnabled = webUI.alternativeUIEnabled;
          CSRFProtection = false;
          ServerDomains = "*";
        }
        (optionalAttrs (webUI.alternativeUIEnabled && webUI.rootFolder == null) {
          RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
        })
        (optionalAttrs (webUI.rootFolder != null) {
          RootFolder = webUI.rootFolder;
        })
        (optionalAttrs (webUI.username != null && !webUI.useSops) {
          # Only set credentials here if NOT using SOPS
          # When useSops=true, credentials are injected at runtime via ExecStartPre
          Username = webUI.username;
        })
        (optionalAttrs (webUI.password != null && !webUI.useSops) {
          # Only set credentials here if NOT using SOPS
          # When useSops=true, credentials are injected at runtime via ExecStartPre
          Password_PBKDF2 = webUI.password;
        })
      ]
    else
      { };
in
{
  # SOPS secrets for WebUI credentials
  sops.secrets = mkIf (webUI != null && webUI.useSops) {
    "qbittorrent/webui/username" = {
      owner = "qbittorrent";
      group = "qbittorrent";
      mode = "0440";
    };
    "qbittorrent/webui/password" = {
      owner = "qbittorrent";
      group = "qbittorrent";
      mode = "0440";
    };
  };

  # Alternative UI support (vuetorrent)
  # No need to copy files - qBittorrent can read directly from Nix store
  environment.systemPackages = optionals (webUI != null && webUI.alternativeUIEnabled) [
    pkgs.vuetorrent
  ];

  # WebUI config for serverConfig
  inherit webUICfg;
}
