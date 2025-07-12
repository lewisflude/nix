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
        "toolkit.telemetry.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "extensions.pocket.enabled" = false;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.strictMode.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "privacy.resistFingerprinting" = true;
        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_ever_enabled" = true;
        
        # Disable automatic backups and session restore to prevent file conflicts
        "browser.sessionstore.max_resumed_crashes" = 0;
        "browser.sessionstore.resume_from_crash" = false;
        "browser.bookmarks.max_backups" = 0;
      };
    };
  };

}
