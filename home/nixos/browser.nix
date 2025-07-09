{ pkgs, lib, ... }:

let
  addons = pkgs.nur.repos.rycee.firefox-addons;
in
{
  programs.firefox = {
    enable = true;

    profiles.default = {
      isDefault = true;

      extensions = {
        force = true;
        packages = with addons; [
          ublock-origin
          kagi-search
        ];
      };

      search = {
        default = "Kagi";
        order = [ "Kagi" ];
        engines.Kagi = {
          urls = [
            {
              template = "https://kagi.com/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          definedAliases = [ "@k" ];
        };
      };

      settings = {
        "media.hardware-video-decoding.enabled" = true;
        "browser.tabs.unloadOnLowMemory" = true;
        "media.ffmpeg.vaapi.enabled" = true;

        "dom.ipc.processCount" = 4; # Reduce processes for lower memory use
        "browser.tabs.remote.autostart" = true;
        "layers.acceleration.force-enabled" = false; # Disable if GPU issues

        "browser.cache.memory.capacity" = 2097152; # Set a lower cache size, like 2GB

        "network.http.max-connections" = 600;
        "network.dnsCacheExpiration" = 600;

        "toolkit.telemetry.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "extensions.pocket.enabled" = false;

        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.strictMode.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "privacy.resistFingerprinting" = true;

        "network.trr.mode" = 2;
        "network.trr.uri" = "https://mozilla.cloudflare-dns.com/dns-query";

        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_ever_enabled" = true;
      };
    };
  };

  home.packages = with pkgs; [
    google-chrome
  ];
}
